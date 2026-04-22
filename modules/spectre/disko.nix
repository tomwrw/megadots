let
  diskId = "/dev/vda";
in {
  flake.modules.nixos.spectre = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = diskId;
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
                  mountOptions = ["umask=0077"];
                };
              };
              luks = {
                size = "100%";
                content = {
                  type = "luks";
                  name = "crypted";
                  passwordFile = "/tmp/luks-password";
                  # These options can improve performance on NVMe drives by adjusting
                  # how LUKS handles I/O operations.
                  extraOpenArgs = [
                    "--allow-discards"
                    "--perf-no_read_workqueue"
                    "--perf-no_write_workqueue"
                  ];
                  settings = {
                    # TRIM/discard operations on SSDs can leak information about
                    # which blocks are unused, potentially revealing filesystem
                    # structure or metadata patterns. This is a common compromise
                    # for SSD performance and longevity.
                    allowDiscards = true;
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [
                      "-L"
                      "nixos"
                      "-f"
                    ];
                    postCreateHook = ''
                      mount -t btrfs /dev/disk/by-label/nixos /mnt
                      btrfs subvolume snapshot -r /mnt /mnt/root-blank
                      umount /mnt
                    '';
                    subvolumes = {
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
                      "/home" = {
                        mountpoint = "/home";
                        mountOptions = [
                          "subvol=home"
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
                        mountpoint = "/swap";
                        swap.swapfile.size = "24G";
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
    fileSystems."/persist".neededForBoot = true;
    fileSystems."/home".neededForBoot = true;
  };
}
