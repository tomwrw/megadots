{ config, lib, ... }:
let
  # Turn a list of NixOS-style { assertion; message; } into a derivation that
  # fails at BUILD time rather than at eval time. Throwing during eval would
  # make every flake command unusable (including 'nix eval' on the thing you are
  # trying to debug); this way a broken invariant surfaces in 'nix flake check'
  # only, with all failures reported at once instead of the first one.
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

  # Fleet-wide invariants. These encode decisions that are easy to undo by
  # accident and expensive to notice: a firewall port opened globally instead of
  # on the LAN interface, a host that forgot 'roles.base' and therefore has no
  # persistence or bootloader, a hardening kernel param silently dropped by the
  # module system's list-priority rules (see hardware/surface-pro.nix).
  #
  # Grown alongside the config: a new invariant lands in the same commit as the
  # change that makes it true, so 'nix flake check' is green at every commit.

  # Deliberately hand-copied from core/security/hardening.nix rather than
  # imported from it: a check that reads the same value it is checking asserts
  # only that Nix can compare a list to itself. Written out here, deleting a
  # param from hardening.nix makes this list disagree and the check fails.
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
        # 'or false': the lanzaboote module is only imported by the host that
        # includes core.boot.lanzaboote, so the option does not exist elsewhere.
        (cfg.boot.lanzaboote.enable or false)
      ];
      missingHardening = lib.subtractLists cfg.boot.kernelParams hardeningParams;
      scoped = lib.attrValues cfg.networking.firewall.interfaces;
      scopedTCP = lib.concatMap (i: i.allowedTCPPorts) scoped;
      # Syncthing is configured per-user through Home Manager, so its ports
      # only reach the host firewall via den.policies.firewall's pipe.expose.
      syncthingUsers = lib.filterAttrs (_: u: u.services.syncthing.enable) cfg.home-manager.users;

      # Options that only EXIST because roles.base imports the module declaring
      # them (impermanence, disko's /persist, sops-nix). Reading them bare on a
      # host that skipped roles.base aborts the whole check during EVALUATION
      # with "attribute 'persistence' missing", printing none of the messages
      # below - the opposite of what this file is for. Defaulting instead lets
      # the assertion fail properly and say which host and why.
      hasPersistence = cfg.environment.persistence."/persist".enable or false;
      persistNeededForBoot = cfg.fileSystems."/persist".neededForBoot or false;
      sopsSshKeyPaths = cfg.sops.age.sshKeyPaths or [ ];

      # The two halves of the ephemeral root live in separate aspects
      # (core.ephemeral-btrfs restores the snapshot, core.disko creates it and
      # mounts subvol=root). Either one alone boots perfectly happily and simply
      # never rolls anything back, so both are asserted.
      hasRollback = cfg.boot.initrd.systemd.services ? restore-root;
      # Matched loosely on purpose: core/disko.nix states 'subvol=root' in
      # mountOptions and disko appends its own 'subvol=/root' from the subvolume
      # name, so both spellings are present and either alone is correct.
      rootOnSubvol = lib.any (o: o == "subvol=root" || o == "subvol=/root") (
        cfg.fileSystems."/".options or [ ]
      );

      # impermanence creates /var/lib/private 0755, but DynamicUser=true services
      # require 0700 (nix-community/impermanence#254, still open). No service in
      # this fleet uses DynamicUser today, so rather than carry Foundry's
      # workaround - two tmpfiles rules plus an mkForce on systemd-tmpfiles-resetup
      # - for a problem that does not exist here, this fires the day one appears.
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
        message = "${name}: /persist must be neededForBoot - activation reads the sops age key from it before systemd starts";
      }
      {
        assertion = cfg.boot.initrd.systemd.enable;
        message = "${name}: boot.initrd.systemd.enable must stay true - impermanence's initrd bind mounts and the restore-root rollback service both depend on it, and both fail silently without it";
      }
      {
        assertion = hasRollback;
        message = "${name}: the restore-root rollback service is missing - the root subvolume would accumulate state forever, with nothing to indicate it, check core.ephemeral-btrfs";
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
        assertion = !(cfg.boot.lanzaboote.enable or false) || !cfg.boot.lanzaboote.allowUnsigned;
        message = "${name}: boot.lanzaboote.allowUnsigned must be pinned false - it defaults to autoGenerateKeys.enable";
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
        # The canary for den.policies.firewall. core.syncthing is included at
        # user scope, so if the expose policy is ever dropped these ports
        # vanish from the host firewall silently, with no eval error.
        assertion = syncthingUsers == { } || lib.elem 22000 scopedTCP;
        message = "${name}: syncthing is enabled for ${toString (lib.attrNames syncthingUsers)} but port 22000 is not open - user-scope firewall quirks are not reaching the host, check den.policies.firewall";
      }
      {
        assertion = missingHardening == [ ];
        message = "${name}: hardening kernel params missing from boot.kernelParams: ${toString missingHardening} - a lower-priority definition of a list option is discarded wholesale, see hardware/surface-pro.nix";
      }
    ];

  rosterAssertions = name: host: [
    {
      # Every LAN-scoped firewall rule hangs off this name, and a wrong one
      # fails open-ended rather than loudly: the rules build fine and simply
      # never match an interface. flatmate shipped with "REPLACE_ME" and had
      # SSH, Syncthing and mDNS firewalled off as a result.
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
        # Build every host for this system. Without this 'nix flake check' only
        # ran treefmt and never noticed that a host stopped evaluating.
        #
        # Host-named attrs come first so a host called "invariants" or "roster"
        # cannot silently replace the check of the same name - the meta
        # assertion below refuses that outright rather than leaving a green
        # check that verifies nothing.
        (lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) hosts) // {
          invariants = mkAssertions pkgs "invariants" (
            [
              {
                # Guards against this system having no hosts at all: mapAttrs
                # over {} yields no assertions, mkAssertions emits `touch $out`,
                # and the check passes having verified nothing. den falls back
                # to lib.systems.flakeExposed when den.systems is empty, so this
                # is one roster edit away rather than hypothetical.
                assertion = hosts != { };
                message = "checks.${system}: no hosts evaluate for this system, so every fleet invariant would pass vacuously";
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
