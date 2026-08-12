{ config, lib, ... }:
let
  # Turns a list of { assertion; message; } into a derivation that fails at
  # build time instead of eval time. Throwing during eval breaks every flake
  # command, including the 'nix eval' I'd be using to debug it. This way a
  # broken invariant only shows up in 'nix flake check', and I get all the
  # failures at once instead of just the first.
  mkAssertions =
    pkgs: name: assertions:
    let
      failures = lib.filter (a: !a.assertion) assertions;
    in
    pkgs.runCommand "check-${name}" { } (
      if failures == [ ] then
        "touch $out"
      else
        ''
          {
            echo '${name}: ${toString (builtins.length failures)} assertion(s) failed'
            ${lib.concatMapStringsSep "\n  " (a: "echo ${lib.escapeShellArg "  - ${a.message}"}") failures}
          } >&2
          exit 1
        ''
    );

  # Invariants across both my hosts. These are the decisions that are easy to
  # undo by accident and expensive to notice: a firewall port opened globally
  # instead of on the LAN interface, a host that forgot 'roles.base' and so has
  # no persistence or bootloader, a hardening kernel param dropped by the
  # module system's list priority rules (see hardware/surface-pro.nix).
  #
  # These grow with the config. A new invariant goes in the same commit as the
  # change that makes it true, so 'nix flake check' is green at every commit.

  # Copied out of hardening.nix by hand, not imported. A check that reads the
  # same value it's checking only proves Nix can compare a list to itself.
  # Written out here, dropping a param from hardening.nix makes the two
  # disagree and the check fails.
  hardeningParams = [
    "init_on_alloc=1"
    "init_on_free=1"
    "slab_nomerge"
    "page_alloc.shuffle=1"
    "vsyscall=none"
  ];

  # How many devices every syncthing user should end up with: one per mesh host
  # that hasn't opted out, plus one per external peer.
  #
  # Counted from the roster and the option, not from the pipe, so this is an
  # independent statement of the same fact rather than a comparison of the pipe
  # with itself. den.policies.syncthing-mesh gathers those records with
  # pipe.collectAll across the whole fleet, and every way that can go wrong is
  # silent: a host dropped from den.schema.host emits nothing, a predicate that
  # stops matching collects nothing, and two peers sharing a name overwrite
  # each other on the way into an attrset. All three land as a device list that
  # is still valid config and still builds - the machine just stops syncing
  # with something, which is exactly the kind of failure I'd notice weeks late.
  expectedPeerCount =
    lib.count (h: h.syncthing.enable && h.syncthing.id != "") (
      lib.concatMap lib.attrValues (lib.attrValues config.flake.roster)
    )
    + lib.length (lib.attrNames config.fleet.externalPeers);

  # The published API. modules/den/namespace.nix exports everything under
  # modules/megadots/ as flake.denful.megadots, and once another config can add
  # this repo as an input, the shape of that attrset is a promise rather than
  # an implementation detail.
  #
  # Two failure modes, both silent. A typo in the namespace name exports an
  # empty attrset - den has no reason to complain, there is simply nothing
  # there. And because den.namespace aliases the whole 'megadots' option path,
  # any setting written under it is legal and gets published as though it were
  # an aspect; megadots.externalPeers did precisely that, and appeared in the
  # export next to real aspects until it became fleet.externalPeers.
  #
  # This does not try to check every aspect's description. den materialises
  # container nodes as aspects too, so a naive walk can't tell an aspect I
  # wrote from a node den derived, and a check that can't tell the difference
  # would either pass vacuously or nag about nodes nobody declared.
  namespaceTrees = [
    "apps"
    "core"
    "desktop"
    "hardware"
    "virtualisation"
  ];
  exported = config.flake.denful.megadots or { };
  # den adds these itself; they aren't aspects and aren't mine to describe.
  exportedTrees = lib.subtractLists [
    "classes"
    "schema"
  ] (lib.attrNames exported);
  undescribedTrees = lib.filter (
    t: (exported.${t}.description or "") == "" || (exported.${t}.description or "") == "Aspect ${t}"
  ) (lib.intersectLists exportedTrees namespaceTrees);

  hostInvariants =
    name: nixos:
    let
      cfg = nixos.config;
      bootloaders = [
        cfg.boot.loader.systemd-boot.enable
        cfg.boot.loader.grub.enable
        # 'or false' because only the host including core.boot.lanzaboote
        # imports that module, so the option doesn't exist anywhere else.
        (cfg.boot.lanzaboote.enable or false)
      ];
      missingHardening = lib.subtractLists cfg.boot.kernelParams hardeningParams;
      scoped = lib.attrValues cfg.networking.firewall.interfaces;
      scopedTCP = lib.concatMap (i: i.allowedTCPPorts) scoped;
      # Syncthing is set up per user through Home Manager, so its ports only
      # reach the host firewall through den.policies.firewall.
      syncthingUsers = lib.filterAttrs (_: u: u.services.syncthing.enable) cfg.home-manager.users;

      # The roster assertion below only sees den hosts. External peers are set
      # as fleet.externalPeers instead, so an unfilled placeholder or a
      # mistyped ID there would sit in the generated config looking plausible
      # and simply never connect. This reads the devices as actually
      # configured, so it covers both sources.
      badDeviceIds = lib.unique (
        lib.concatMap (
          u:
          lib.attrNames (
            lib.filterAttrs (_: d: builtins.stringLength d.id != 63) u.services.syncthing.settings.devices
          )
        ) (lib.attrValues syncthingUsers)
      );

      shortMeshes = lib.attrNames (
        lib.filterAttrs (
          _: u: lib.length (lib.attrNames u.services.syncthing.settings.devices) != expectedPeerCount
        ) syncthingUsers
      );

      # A home.persistence path that no longer matches where the app writes
      # gives no error at all, the state is just gone after every boot.
      # Firefox is the one where I can't eyeball the path: Home Manager works
      # out programs.firefox.configPath itself and nothing here sets it, so an
      # upstream change moves my profile out from under the entry. Caught me
      # once already, hence this.
      firefoxUsersMissingPersist = lib.attrNames (
        lib.filterAttrs (
          _: u:
          u.programs.firefox.enable
          && !lib.any (d: d.directory == u.programs.firefox.configPath) (
            u.home.persistence."/persist".directories or [ ]
          )
        ) cfg.home-manager.users
      );

      # These options only exist because roles.base imports the module that
      # declares them. Read bare on a host that skipped roles.base, the whole
      # check dies during eval with "attribute 'persistence' missing" and
      # prints none of the messages below, which is the opposite of what I
      # want. Defaulting lets the assertion fail properly and name the host.
      hasPersistence = cfg.environment.persistence."/persist".enable or false;
      persistNeededForBoot = cfg.fileSystems."/persist".neededForBoot or false;
      sopsSshKeyPaths = cfg.sops.age.sshKeyPaths or [ ];

      # The ephemeral root is split across two aspects: core.ephemeral-btrfs
      # restores the snapshot, core.disko creates it and mounts subvol=root.
      # Either one on its own boots quite happily and never rolls back, so
      # check for both.
      hasRollback = cfg.boot.initrd.systemd.services ? restore-root;
      # Loose match on purpose. core/disko.nix sets 'subvol=root' in
      # mountOptions and disko appends its own 'subvol=/root', so both
      # spellings turn up and either one alone is correct.
      rootOnSubvol = lib.any (o: o == "subvol=root" || o == "subvol=/root") (
        cfg.fileSystems."/".options or [ ]
      );

      # impermanence creates /var/lib/private 0755 but DynamicUser services
      # need 0700 (impermanence#254, still open). Nothing I run uses
      # DynamicUser today, so instead of carrying Foundry's workaround for a
      # problem I don't have, this fires the day I do.
      dynamicUserServices = lib.attrNames (
        lib.filterAttrs (_: s: s.serviceConfig.DynamicUser or false) cfg.systemd.services
      );
      privateHandled = lib.any (r: lib.hasInfix "/var/lib/private" r) (cfg.systemd.tmpfiles.rules or [ ]);

      # The home-persist quirk is consumed in one place, core.impermanence's
      # provides.to-users half. If that consumer is ever dropped the pool is
      # still collected, still valid, and simply never read - every persisted
      # home path disappears with no eval error at all. These three catch it,
      # and they need to stay independent: they fail for different reasons.
      hmUsers = cfg.home-manager.users;
      persistedDirs = u: map (d: d.directory) (u.home.persistence."/persist".directories or [ ]);
      usersMissingStore = lib.attrNames (
        lib.filterAttrs (
          _: u: !(u.home.persistence."/persist".hideMounts or false) || persistedDirs u == [ ]
        ) hmUsers
      );
      # A user-scope producer (apps.shell.zsh emits home-persist directly).
      usersMissingUserScoped = lib.attrNames (
        lib.filterAttrs (_: u: !lib.elem ".local/share/zsh" (persistedDirs u)) hmUsers
      );
      # A host-scope producer routed through provides.to-users (desktop.gnome).
      # Guarded on GNOME actually being enabled, so a headless host would not
      # fail an assertion about a desktop it never asked for.
      usersMissingHostScoped = lib.optionals cfg.services.desktopManager.gnome.enable (
        lib.attrNames (lib.filterAttrs (_: u: !lib.elem ".config/dconf" (persistedDirs u)) hmUsers)
      );

      # desktop.stylix now takes its scheme and wallpaper from options set in
      # users/tomwrw rather than hardcoding them. An option nobody sets fails
      # loudly, which is why it is options and not a bare parametric aspect -
      # but the theme is also the sort of thing that could quietly stop
      # applying, so check the far end: Stylix on, and an actual image.
      usersMissingTheme = lib.attrNames (
        lib.filterAttrs (_: u: !(u.stylix.enable or false) || (u.stylix.image or null) == null) hmUsers
      );

      # den.schema.host declares linux-kernel.channel and .optimization for
      # every host, but only a host that includes core.linux-kernel has
      # anything that reads them. Setting optimization = "zen4" on a host
      # without the aspect is accepted, passes the roster check, and does
      # precisely nothing - the same silent-no-op the quirk policies in
      # den/quirks.nix exist to prevent, one layer up in the schema.
      #
      # Checked by outcome rather than by asking whether the aspect is in the
      # list: if the settings are non-default, the host had better be running a
      # CachyOS kernel.
      kernelRoster =
        config.flake.roster.${nixos.pkgs.stdenv.hostPlatform.system}.${name}.linux-kernel or null;
      kernelSettingsIdle =
        kernelRoster == null
        || (kernelRoster.optimization == "generic" && kernelRoster.channel == "latest");
      kernelIsCachy = lib.hasInfix "cachyos" (cfg.boot.kernelPackages.kernel.pname or "");

      # core.seed derives the tmpfiles ownership, the chown unit and what
      # 'just deploy' copies from one list per producing aspect. The rule that
      # used to be prose - "a seeded file with no persistence entry sits in
      # /persist and never reaches my home, which looks exactly like the deploy
      # having skipped it" - is checkable now that both come from quirks.
      seeded = cfg.megadots.seed or { };
      persistedFiles = u: map (f: f.file) (u.home.persistence."/persist".files or [ ]);
      seededNotPersisted = lib.concatLists (
        lib.mapAttrsToList (
          owner: files: lib.subtractLists (persistedFiles (hmUsers.${owner} or { })) files
        ) seeded
      );
      absoluteSeeds = lib.concatLists (
        lib.mapAttrsToList (_: files: lib.filter (f: lib.hasPrefix "/" f) files) seeded
      );

      # The USB is flat, one directory per user, while these destinations are
      # nested - so 'just deploy' maps source to destination by basename. That
      # only works while the basenames are distinct: two seeded files called
      # 'config' in different directories would both be copied from the same
      # place, and the deploy would look like it had worked.
      collidingSeeds = lib.concatLists (
        lib.mapAttrsToList (
          _: files:
          let
            bases = map baseNameOf files;
          in
          lib.filter (b: lib.count (x: x == b) bases > 1) (lib.unique bases)
        ) seeded
      );

      # den.batteries.unfree collects these; den's own predicate builder, which
      # is in den.default, turns them into allowUnfreePredicate. Both halves are
      # invisible from here, so the checks below exercise the predicate rather
      # than just look at the list.
      unfreeNames = cfg.unfree.packages or [ ];
      unfreePredicate = cfg.nixpkgs.config.allowUnfreePredicate or null;
      # lib.getName reads pname, so this is the shape the real predicate sees.
      unfreeAllowed =
        n:
        unfreePredicate {
          pname = n;
          version = "0";
        };
    in
    [
      {
        assertion = usersMissingTheme == [ ];
        message = "${name}: Stylix is not applied for ${toString usersMissingTheme} - desktop.stylix reads megadots.theme.scheme and .wallpaper from the user aspect, so this fires if the aspect stops being included or the theme options stop reaching it";
      }
      {
        assertion = kernelSettingsIdle || kernelIsCachy;
        message = "${name}: den.hosts sets linux-kernel.* away from its defaults, but this host is not running a CachyOS kernel - core.linux-kernel is the aspect that reads those options and it is not in this host's includes, so the setting does nothing at all";
      }
      {
        assertion = seeded != { };
        message = "${name}: megadots.seed is empty - core.seed collected no 'seed' quirk data at all, so nothing owns the deploy-seeded keys and the first boot after a deploy leaves them root:root";
      }
      {
        assertion = seededNotPersisted == [ ];
        message = "${name}: ${toString seededNotPersisted} are seeded by 'just deploy' but not persisted - they would sit in /persist and never be mounted into the home, which looks exactly like the deploy having skipped them";
      }
      {
        assertion = collidingSeeds == [ ];
        message = "${name}: ${toString collidingSeeds} appear as the basename of more than one seeded file - 'just deploy' copies each from {{ usb }}/users/<owner>/<basename>, so the collision would silently seed the same file to both destinations";
      }
      {
        assertion = absoluteSeeds == [ ];
        message = "${name}: ${toString absoluteSeeds} are absolute paths - 'seed' entries are relative to the owner's home, and core.seed prefixes them itself";
      }
      {
        assertion = usersMissingStore == [ ];
        message = "${name}: ${toString usersMissingStore} have no persisted home directories, or hideMounts is unset - core.impermanence's provides.to-users consumer is what builds home.persistence out of the home-persist quirk, and without it every entry is collected and then silently discarded";
      }
      {
        assertion = usersMissingUserScoped == [ ];
        message = "${name}: '.local/share/zsh' is missing for ${toString usersMissingUserScoped} - that comes from a user-scope aspect emitting home-persist directly, so this is the canary for the quirk no longer reaching the consumer within a single user scope";
      }
      {
        assertion = usersMissingHostScoped == [ ];
        message = "${name}: '.config/dconf' is missing for ${toString usersMissingHostScoped} - that comes from desktop.gnome, a host-scope aspect, through provides.to-users; it fails independently of the zsh canary above because it exercises the host-to-user delivery rather than the quirk itself";
      }
      {
        assertion = unfreePredicate != null && lib.all unfreeAllowed unfreeNames;
        message = "${name}: allowUnfreePredicate does not allow every name collected by den.batteries.unfree (${toString unfreeNames}) - the battery reached this host but den's predicate builder did not, so these packages will fail to build with an unfree licence error";
      }
      {
        assertion = !(cfg.nixpkgs.config.allowUnfree or false);
        message = "${name}: nixpkgs.config.allowUnfree must stay false - unfree packages are allowed by name through den.batteries.unfree, and a blanket true would let any of them in unnoticed";
      }
      {
        # spotify is declared by a user-scope aspect. den's battery emits into
        # the host's OS class as well as homeManager, and that second half is
        # what makes home-manager.useGlobalPkgs work; if it ever stops firing,
        # nothing else here would notice.
        assertion = lib.elem "spotify" unfreeNames;
        message = "${name}: 'spotify' is missing from unfree.packages - it is declared at user scope, so this is the canary for den.batteries.unfree no longer delivering from a user aspect up to the host predicate";
      }
      {
        assertion = cfg.networking.firewall.enable;
        message = "${name}: networking.firewall.enable must stay true";
      }
      {
        assertion = cfg.networking.firewall.allowedTCPPorts == [ ];
        message = "${name}: firewall TCP ports must be interface-scoped, not global (found ${toString cfg.networking.firewall.allowedTCPPorts})";
      }
      {
        assertion = cfg.networking.firewall.allowedUDPPorts == [ ];
        message = "${name}: firewall UDP ports must be interface-scoped, not global (found ${toString cfg.networking.firewall.allowedUDPPorts})";
      }
      {
        assertion = !cfg.services.openssh.enable || !cfg.services.openssh.openFirewall;
        message = "${name}: services.openssh.openFirewall opens port 22 on every interface - keep it false and scope the port";
      }
      {
        assertion = !cfg.services.avahi.enable || !cfg.services.avahi.openFirewall;
        message = "${name}: services.avahi.openFirewall opens 5353 on every interface - keep it false and scope the port";
      }
      {
        assertion = !cfg.users.mutableUsers;
        message = "${name}: users.mutableUsers must stay false (declarative users only)";
      }
      {
        assertion = hasPersistence;
        message = "${name}: environment.persistence.\"/persist\" is not enabled - root is rolled back to a blank snapshot on every boot, so this host would lose all state on reboot";
      }
      {
        assertion = persistNeededForBoot;
        message = "${name}: /persist must be neededForBoot - activation reads the sops age key off it in the initrd";
      }
      {
        assertion = cfg.boot.initrd.systemd.enable;
        message = "${name}: boot.initrd.systemd.enable must stay true - impermanence's initrd bind mounts and the restore-root rollback service both depend on it, and both stop working without it";
      }
      {
        assertion = hasRollback;
        message = "${name}: the restore-root rollback service is missing - the root subvolume would just keep accumulating state with nothing to show for it, check core.ephemeral-btrfs";
      }
      {
        assertion = rootOnSubvol;
        message = "${name}: / must be the btrfs 'root' subvolume (subvol=root) - core.ephemeral-btrfs restores root-blank over it, and disko's postCreateHook is what creates that snapshot";
      }
      {
        assertion = dynamicUserServices == [ ] || privateHandled;
        message = "${name}: ${toString dynamicUserServices} use DynamicUser, which needs /var/lib/private at 0700, but impermanence creates it 0755 (nix-community/impermanence#254) - add tmpfiles rules for /persist/var/lib/private and /var/lib/private plus systemd-tmpfiles-resetup.serviceConfig.RemainAfterExit = false";
      }
      {
        assertion = lib.count lib.id bootloaders == 1;
        message = "${name}: exactly one bootloader must be enabled (systemd-boot/grub/lanzaboote)";
      }
      {
        assertion = !cfg.boot.loader.systemd-boot.editor;
        message = "${name}: boot.loader.systemd-boot.editor must be false - it lets anyone at the console append kernel parameters";
      }
      {
        assertion = cfg.boot.loader.systemd-boot.configurationLimit != null;
        message = "${name}: boot.loader.systemd-boot.configurationLimit must be bounded - the 1G ESP holds whole UKIs";
      }
      {
        assertion =
          !(cfg.boot.lanzaboote.autoGenerateKeys.enable or false) || cfg.boot.lanzaboote.allowUnsigned;
        message = "${name}: boot.lanzaboote.allowUnsigned must stay true while autoGenerateKeys is on - lzbt runs inside nixos-install, but the keys are only generated on the first boot, so pinning it false makes a from-scratch deploy impossible";
      }
      {
        assertion = sopsSshKeyPaths == [ ];
        message = "${name}: sops.age.sshKeyPaths must stay empty - the dedicated age key in /persist is the only decryption identity";
      }
      {
        assertion = cfg.security.sudo.execWheelOnly;
        message = "${name}: security.sudo.execWheelOnly must stay true - only wheel should be able to execute the setuid binary";
      }
      {
        assertion =
          !cfg.services.openssh.enable
          || (
            cfg.services.openssh.hostKeys != [ ]
            && lib.all (k: lib.hasPrefix "/persist/" k.path) cfg.services.openssh.hostKeys
          );
        message = "${name}: every ssh host key must live under /persist - / is rolled back to a blank snapshot each boot, so anything else regenerates host identity every time";
      }
      {
        assertion = lib.length scoped == 1 && lib.elem 22 scopedTCP;
        message = "${name}: ssh must be reachable on exactly one LAN-scoped interface - the firewall quirk consumer in core.networking is not producing rules";
      }
      {
        # The canary for den.policies.firewall. apps.sync.syncthing comes in at
        # user scope, so if I ever drop the expose policy these ports just
        # disappear from the host firewall with no eval error.
        assertion = syncthingUsers == { } || lib.elem 22000 scopedTCP;
        message = "${name}: syncthing is enabled for ${toString (lib.attrNames syncthingUsers)} but port 22000 is not open - user-scope firewall quirks are not reaching the host, check den.policies.firewall";
      }
      {
        assertion = badDeviceIds == [ ];
        message = "${name}: syncthing devices ${toString badDeviceIds} do not have a 63-character device ID - external peers and mesh hosts are both set in modules/den/hosts.nix";
      }
      {
        assertion = shortMeshes == [ ];
        message = "${name}: syncthing users ${toString shortMeshes} do not have exactly ${toString expectedPeerCount} devices - the syncthing-peer pipe in modules/den/mesh.nix has lost a peer (a host dropped from den.schema.host, a collectAll predicate that stopped matching, or two peers sharing a name), and the only symptom on the machine is data that quietly stops arriving";
      }
      {
        assertion = firefoxUsersMissingPersist == [ ];
        message = "${name}: firefox is enabled for ${toString firefoxUsersMissingPersist} but programs.firefox.configPath is not in that user's home.persistence directories - the profile (Stylix theme, extensions, cookies) would be thrown away on every boot with no error";
      }
      {
        assertion = missingHardening == [ ];
        message = "${name}: hardening kernel params missing from boot.kernelParams: ${toString missingHardening} - a lower-priority definition of a list option is discarded wholesale, see hardware/surface-pro.nix";
      }
    ];

  # What has to survive with no NixOS underneath it. den.homes/tomwrw evaluates
  # the same user aspect as both real machines, minus the host, and everything
  # here is a way that can go wrong in silence.
  #
  # The failure mode this guards is den's dispatch: a class module whose scope
  # arguments den can't satisfy is dropped, and an aspect written as a bare
  # function of { host, ... } is read as parametric over scope and dropped too.
  # Neither says anything. The config still evaluates, still builds, and is
  # just quietly missing whatever that aspect did - which is how apps/shell/zsh
  # came to contribute nothing here for the sake of two nixos-rebuild aliases.
  homeInvariants =
    name: home:
    let
      cfg = home.config;
    in
    [
      {
        # The canary for silent-inert dispatch, and the reason it reads for fzf
        # rather than programs.zsh.enable: zsh is turned on by
        # den.batteries.user-shell, so it stays true even when the aspect that
        # configures the shell has vanished entirely. fzf and dotDir come from
        # apps/shell/zsh.nix itself and are false and "$HOME" when it doesn't
        # land.
        assertion = cfg.programs.fzf.enable && lib.hasSuffix "/zsh" cfg.programs.zsh.dotDir;
        message = "home ${name}: apps.shell.zsh has not landed (fzf ${lib.boolToString cfg.programs.fzf.enable}, dotDir ${cfg.programs.zsh.dotDir}) - den drops an aspect written as a bare function of scope arguments when the scope can't supply them, with no error";
      }
      {
        # Proves impermanence stayed on the host side. home.persistence only
        # exists because the NixOS impermanence module injects it, so an app
        # aspect writing it directly is an aspect that can't leave this repo.
        # The home-persist quirk exists precisely to stop that.
        assertion = !(cfg.home ? persistence);
        message = "home ${name}: home.persistence is set in a standalone home - an aspect is writing an option that only exists inside a NixOS host, use the home-persist quirk instead";
      }
      {
        assertion = cfg.stylix.enable && cfg.programs.git.enable && cfg.programs.firefox.enable;
        message = "home ${name}: one of stylix, git or firefox is missing - these come from user-scope aspects that must not need a host";
      }
      {
        # desktop.fonts installs system-wide on a host and has no system to do
        # it here, so den.schema.home pulls in its provides.home sub-aspect. A
        # provides.<name> that nothing includes delivers nowhere and says
        # nothing about it.
        assertion = cfg.fonts.fontconfig.enable;
        message = "home ${name}: fonts.fontconfig is off - the desktop.fonts provides.home sub-aspect is not being included by den.schema.home";
      }
      {
        assertion = !cfg.services.syncthing.enable;
        message = "home ${name}: syncthing is enabled without a host - its secrets are named syncthing/<host>/... and cannot exist here, check the excludes in modules/den/homes.nix";
      }
    ];

  rosterAssertions = name: host: [
    {
      # Every LAN firewall rule hangs off this name, and getting it wrong
      # fails quietly: the rules build fine and never match an interface.
      # flatmate shipped with "REPLACE_ME" and had SSH, Syncthing and mDNS
      # firewalled off because of it.
      assertion =
        host.lanInterface != ""
        && host.lanInterface != "REPLACE_ME"
        && builtins.stringLength host.lanInterface < 16;
      message = "${name}: network.lanInterface must name a real interface (see `ip -br link`), not ${host.lanInterface}";
    }
    {
      assertion = lib.hasPrefix "/dev/disk/by-id/" host.id;
      message = "${name}: disk.id must be a stable /dev/disk/by-id/ path, not ${host.id}";
    }
    {
      assertion = !host.syncthing.enable || builtins.stringLength host.syncthing.id == 63;
      message = "${name}: syncthing.id must be a 63-character device ID while syncthing is enabled";
    }
  ];
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      hosts = lib.filterAttrs (
        _: nixos: nixos.pkgs.stdenv.hostPlatform.system == system
      ) config.flake.nixosConfigurations;
      roster = config.flake.roster.${system} or { };
      homes = lib.filterAttrs (_: home: home.pkgs.stdenv.hostPlatform.system == system) (
        config.flake.homeConfigurations or { }
      );
    in
    {
      checks =
        # Build every host for this system. Without this 'nix flake check'
        # only ran treefmt and never noticed a host had stopped evaluating.
        #
        # Host names go first so a host called "invariants" or "roster" can't
        # quietly replace the check of the same name. The assertion below
        # refuses that outright instead of leaving a green check that tests
        # nothing.
        (lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) hosts)
        # Every standalone home for this system, built the same way. A home
        # that stops evaluating is the whole point of having one, so it must
        # fail 'nix flake check' rather than wait to be noticed.
        // (lib.mapAttrs (_: home: home.activationPackage) homes)
        // {
          invariants = mkAssertions pkgs "invariants" (
            [
              {
                # Catches this system having no hosts at all. mapAttrs over {}
                # gives no assertions, mkAssertions just emits 'touch $out',
                # and the check passes having tested nothing. den falls back to
                # lib.systems.flakeExposed when den.systems is empty, so that's
                # one roster edit away, not hypothetical.
                assertion = hosts != { };
                message = "checks.${system}: no hosts evaluate for this system, so every invariant here would pass without testing anything";
              }
              {
                assertion = !(hosts ? invariants) && !(hosts ? roster) && !(hosts ? homes);
                message = "checks.${system}: a host is named 'invariants', 'roster' or 'homes' and would shadow the check of that name - rename the host";
              }
              {
                # Homes share the checks attrset with hosts, so the same
                # shadowing applies across both sets at once.
                assertion = lib.intersectLists (lib.attrNames homes) (lib.attrNames hosts) == [ ];
                message = "checks.${system}: a home and a host share a name (${toString (lib.intersectLists (lib.attrNames homes) (lib.attrNames hosts))}) - one silently replaces the other's check";
              }
            ]
            ++ lib.concatLists (lib.mapAttrsToList hostInvariants hosts)
          );
          homes = mkAssertions pkgs "homes" (
            [
              {
                # Same vacuity trap as the roster check. den.homes is easy to
                # narrow to one system, and then this whole check quietly
                # proves nothing on the other.
                assertion = homes != { };
                message = "checks.${system}: no standalone homes evaluate for this system, so every home invariant would pass vacuously - is den.homes still declared for ${system}?";
              }
              {
                assertion = !(homes ? invariants) && !(homes ? roster) && !(homes ? homes);
                message = "checks.${system}: a home is named 'invariants', 'roster' or 'homes' and would shadow the check of that name - rename the home";
              }
            ]
            ++ lib.concatLists (lib.mapAttrsToList homeInvariants homes)
          );
          roster = mkAssertions pkgs "roster" (
            [
              {
                assertion = roster != { };
                message = "checks.${system}: flake.roster is empty for this system, so every roster assertion would pass vacuously";
              }
            ]
            ++ lib.concatLists (lib.mapAttrsToList rosterAssertions roster)
          );
          namespace = mkAssertions pkgs "namespace" [
            {
              assertion = exported != { };
              message = "checks.${system}: flake.denful.megadots is empty - the namespace name in modules/den/namespace.nix does not match what anything writes to, and den exports an empty attrset without complaining";
            }
            {
              assertion = lib.sort (a: b: a < b) exportedTrees == namespaceTrees;
              message = "checks.${system}: flake.denful.megadots exports ${
                toString (lib.sort (a: b: a < b) exportedTrees)
              } but should export exactly ${toString namespaceTrees} - either a new tree of aspects needs adding to namespaceTrees in this file, or a plain setting has been written under megadots.* and is now published as though it were an aspect (see fleet.externalPeers in modules/den/mesh.nix)";
            }
            {
              assertion = undescribedTrees == [ ];
              message = "checks.${system}: exported namespace trees ${toString undescribedTrees} have no description of their own - these are the first thing anyone reading this as an API sees, set them in modules/den/namespace.nix";
            }
          ];
        };
    };
}
