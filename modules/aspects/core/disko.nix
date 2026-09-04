{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # A declarative LUKS-on-btrfs layout with subvolumes and a swapfile, sized
  # from the host roster.
  den.aspects.disko =
    { host, ... }:
    let
      # Name of the opened LUKS mapping. Bound once so the postCreateHook and
      # content.name below can't drift apart.
      luksName = "crypted";
    in
    {
      nixos = _: {
        imports = [ inputs.disko.nixosModules.disko ];

        # No boot.tmp.cleanOnBoot. / comes back blank every boot anyway, so
        # there's nothing for it to clean.

        disko.devices = {
          disk = {
            main = {
              type = "disk";
              device = host.disk.id;
              content = {
                type = "gpt";
                partitions = {
                  ESP = {
                    size = "1024M";
                    type = "EF00";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  luks = {
                    size = "100%";
                    content = {
                      type = "luks";
                      name = luksName;
                      # .settings., not .extraOpenArgs.: disko passes settings
                      # through to boot.initrd.luks.devices, where extraOpenArgs
                      # only applies to its install-time cryptsetup open.
                      settings = {
                        # TRIM leaks which blocks are unused. Worth it for SSD
                        # life and speed.
                        allowDiscards = true;
                        # Skip dm-crypt.s queues: on NVMe they cost more latency
                        # than they buy throughput.
                        bypassWorkqueues = true;
                      };
                      content = {
                        type = "btrfs";
                        extraArgs = [ "-f" ];

                        # Snapshot the 'root' subvolume read-only while it's
                        # still empty. core.ephemeral-btrfs restores this every
                        # boot, so it has to be taken at format time. Any later
                        # and it already has the system in it.
                        #
                        # It has to be '/mnt/root' and not '/mnt'. The plain
                        # mount lands on the top level, which by this point
                        # already holds root, nix, persist and swap as nested
                        # subvolumes, and btrfs snapshots don't recurse. Each
                        # nested subvolume comes out of the snapshot as an
                        # inode 2 placeholder (BTRFS_EMPTY_SUBVOL_DIR_OBJECTID),
                        # which the kernel makes permanently unwritable and
                        # fails with EPERM.
                        #
                        # nix, persist and swap get their real subvolumes
                        # mounted over the placeholders, so they look fine.
                        # /root does not: root.s home ends up read-only and
                        # everything that writes there breaks, down to
                        # nix-daemon losing its binary cache disk cache and
                        # rebuilding stdenv from source.
                        postCreateHook = ''
                          mount -t btrfs /dev/mapper/${luksName} /mnt
                          btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
                          umount /mnt
                        '';

                        subvolumes = {
                          # Rolled back to root-blank every boot. /home sits
                          # inside it on purpose: user state is opt-in through
                          # persist.home, as system state is through
                          # persist.system.
                          "/root" = {
                            mountpoint = "/";
                            mountOptions = [
                              "subvol=root"
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "/nix" = {
                            mountpoint = "/nix";
                            mountOptions = [
                              "subvol=nix"
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "/persist" = {
                            mountpoint = "/persist";
                            mountOptions = [
                              "subvol=persist"
                              "compress=zstd"
                              "noatime"
                            ];
                          };
                          "/swap" = {
                            swap.swapfile.size = host.disk.swapSize;
                            mountpoint = "/swap";
                            mountOptions = [
                              "noatime"
                            ];
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };

        # impermanence asserts this too, but it belongs here where the mount is
        # declared. Activation reads the sops age key off /persist, so it has
        # to be mounted in the initrd.
        fileSystems."/persist".neededForBoot = true;
      };
    };
}
