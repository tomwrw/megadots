_: {
  # Rolls the root subvolume back to a blank snapshot in the initrd, on every
  # boot, so anything not persisted is gone by login. Shape borrowed from
  # Misterio77.s Foundry.
  #
  # root-blank itself is taken by disko.s postCreateHook at format time. It has
  # to be: by first boot nixos-anywhere has already written the system into
  # .root. and the snapshot would not be blank.
  den.aspects.ephemeral-btrfs.nixos =
    {
      config,
      lib,
      utils,
      ...
    }:
    let
      root = config.fileSystems."/";

      # impermanence bind mounts a persisted dir in the initrd only if it is in
      # pathsNeededForBoot, and those mounts run before activation - so on a
      # first boot nothing has created the sources yet. Derived from the config
      # rather than hardcoded, so adding a persisted dir cannot miss one.
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
            # Stop rather than delete. The delete and the restore aren't
            # atomic, so on a volume that never got the postCreateHook I'd
            # lose the root subvolume and get nothing back.
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
          # utils.escapeSystemdPath rather than the string mangling Foundry
          # does by hand. It handles cases the hand-rolled one doesn't. Note
          # it's on 'utils', there's no lib.escapeSystemdPath.
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
