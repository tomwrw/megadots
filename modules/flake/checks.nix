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

      # The roster assertion below only sees den hosts. External peers live in
      # core/syncthing.nix instead, so an unfilled placeholder or a mistyped ID
      # there would sit in the generated config looking plausible and simply
      # never connect. This reads the devices as actually configured, so it
      # covers both sources.
      badDeviceIds = lib.unique (
        lib.concatMap (
          u:
          lib.attrNames (
            lib.filterAttrs (_: d: builtins.stringLength d.id != 63) u.services.syncthing.settings.devices
          )
        ) (lib.attrValues syncthingUsers)
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
    in
    [
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
        # The canary for den.policies.firewall. core.syncthing comes in at
        # user scope, so if I ever drop the expose policy these ports just
        # disappear from the host firewall with no eval error.
        assertion = syncthingUsers == { } || lib.elem 22000 scopedTCP;
        message = "${name}: syncthing is enabled for ${toString (lib.attrNames syncthingUsers)} but port 22000 is not open - user-scope firewall quirks are not reaching the host, check den.policies.firewall";
      }
      {
        assertion = badDeviceIds == [ ];
        message = "${name}: syncthing devices ${toString badDeviceIds} do not have a 63-character device ID - external peers are set in modules/aspects/core/syncthing.nix, mesh hosts in modules/den/hosts.nix";
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
        (lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) hosts) // {
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
                assertion = !(hosts ? invariants) && !(hosts ? roster);
                message = "checks.${system}: a host is named 'invariants' or 'roster' and would shadow the check of that name - rename the host";
              }
            ]
            ++ lib.concatLists (lib.mapAttrsToList hostInvariants hosts)
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
        };
    };
}
