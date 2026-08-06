_: {
  # An ephemeral root: the 'root' subvolume is deleted and restored from the
  # read-only 'root-blank' snapshot on every boot, so anything not listed in
  # core.impermanence is gone by the time the system is up.
  #
  # Shape follows Misterio77/Foundry's hosts/common/optional/ephemeral-btrfs.nix.
  # Nothing packages this - impermanence covers persistence only, not rollback -
  # so every config in the ecosystem carries its own copy of these ~40 lines.
  #
  # This is one half of a mechanism: 'root-blank' itself is taken by disko's
  # postCreateHook in core/disko.nix, at format time. It cannot be created here
  # on first boot instead, tempting as that would be - by the time a host boots,
  # nixos-anywhere has already written the installed system into 'root', so the
  # snapshot would not be blank and every later "rollback" would restore a dirty
  # tree. modules/flake/checks.nix asserts the two halves stay together.
  #
  # Only the systemd-initrd path is implemented. Foundry also carries a legacy
  # boot.initrd.postDeviceCommands branch for hosts without it; here that branch
  # would be unreachable, because core/initrd.nix sets boot.initrd.systemd.enable
  # fleet-wide AND checks.nix asserts it stays true. Turning systemd-initrd off
  # therefore fails the build, which is the same protection the dead branch was
  # there to provide.
  den.aspects.core.ephemeral-btrfs.nixos =
    {
      config,
      lib,
      utils,
      ...
    }:
    let
      root = config.fileSystems."/";

      # impermanence bind-mounts a persisted directory in the initrd only when
      # it is in utils.pathsNeededForBoot, and those mounts run before NixOS
      # activation - so on a first boot nothing has created their sources yet
      # and the mounts fail. Pre-create exactly that set.
      #
      # Derived rather than hand-listed (Foundry hardcodes
      # /persist/var/{log,lib/{nixos,systemd}}): adding a persisted directory
      # that lands in pathsNeededForBoot would silently not be covered, and the
      # hardcoded list also names /var/lib/systemd, which is not initrd-mounted
      # at all. Reading core.impermanence's config from here couples the two
      # aspects, which is fine - roles.base takes both and neither works alone.
      initrdSources = lib.filter (
        d: lib.elem d.dirPath utils.pathsNeededForBoot
      ) config.environment.persistence."/persist".directories;

      wipeScript = ''
        mkdir /tmp -p
        MNTPOINT=$(mktemp -d)
        (
          mount -t btrfs -o subvol=/ ${root.device} "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          echo "Creating needed directories"
          mkdir -p ${
            lib.concatMapStringsSep " " (
              d: ''"$MNTPOINT/persist"${lib.escapeShellArg d.dirPath}''
            ) initrdSources
          }

          if [ -e "$MNTPOINT/dont-wipe" ]; then
            echo "Skipping wipe"
          elif [ ! -e "$MNTPOINT/root-blank" ]; then
            # Refuse rather than delete. The delete/restore pair is not atomic,
            # so without this a volume that never got disko's postCreateHook
            # would lose its root subvolume and gain nothing back - an
            # unbootable host, and the next boot would fail identically with
            # nothing left to recover from.
            echo "root-blank snapshot is missing - refusing to delete the root subvolume" >&2
            exit 1
          else
            echo "Cleaning root subvolume"
            btrfs subvolume delete -R "$MNTPOINT/root"
            echo "Restoring blank subvolume"
            btrfs subvolume snapshot "$MNTPOINT/root-blank" "$MNTPOINT/root"
          fi
        )
      '';
    in
    {
      boot.initrd = {
        supportedFilesystems = [ "btrfs" ];

        systemd.services.restore-root = {
          description = "Rollback btrfs rootfs";
          wantedBy = [ "initrd.target" ];
          # utils.escapeSystemdPath, not the hand-rolled splitString/replaceString
          # that Foundry uses - it is the canonical helper (from the 'utils'
          # module argument; there is no lib.escapeSystemdPath) and it escapes
          # cases the hand-rolled version does not. For this fleet's
          # /dev/mapper/crypted both produce dev-mapper-crypted.device.
          requires = [ "${utils.escapeSystemdPath root.device}.device" ];
          after = [ "${utils.escapeSystemdPath root.device}.device" ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = wipeScript;
        };
      };
    };
}
