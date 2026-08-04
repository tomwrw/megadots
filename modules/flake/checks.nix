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
  # on the LAN interface, a host that forgot 'roles.default' and therefore has no
  # preservation or bootloader, a hardening kernel param silently dropped by the
  # module system's list-priority rules (see hardware/surface-pro.nix).
  #
  # Grown alongside the config: a new invariant lands in the same commit as the
  # change that makes it true, so 'nix flake check' is green at every commit.
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
        assertion = !cfg.services.openssh.openFirewall;
        message = "${name}: services.openssh.openFirewall opens port 22 on every interface - keep it false and scope the port";
      }
      {
        assertion = !cfg.services.avahi.openFirewall;
        message = "${name}: services.avahi.openFirewall opens 5353 on every interface - keep it false and scope the port";
      }
      {
        assertion = !cfg.users.mutableUsers;
        message = "${name}: users.mutableUsers must stay false (declarative users only)";
      }
      {
        assertion = cfg.preservation.enable;
        message = "${name}: preservation.enable is false - root is a tmpfs, so this host would lose all state on reboot";
      }
      {
        assertion = cfg.fileSystems."/persist".neededForBoot;
        message = "${name}: /persist must be neededForBoot - activation reads the sops age key from it before systemd starts";
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
        assertion = cfg.sops.age.sshKeyPaths == [ ];
        message = "${name}: sops.age.sshKeyPaths must stay empty - the dedicated age key in /persist is the only decryption identity";
      }
      {
        assertion = cfg.security.sudo.execWheelOnly;
        message = "${name}: security.sudo.execWheelOnly must stay true - only wheel should be able to execute the setuid binary";
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
        (lib.mapAttrs (_: nixos: nixos.config.system.build.toplevel) hosts) // {
          invariants = mkAssertions pkgs "invariants" (
            lib.concatLists (lib.mapAttrsToList hostInvariants hosts)
          );
          roster = mkAssertions pkgs "roster" (lib.concatLists (lib.mapAttrsToList rosterAssertions roster));
        };
    };
}
