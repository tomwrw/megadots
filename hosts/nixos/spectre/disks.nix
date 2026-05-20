# Disk configuration for spectre, using a tmpfs root for impermanence.
# /home and /persist live on btrfs subvolumes so they survive the
# wiped-on-boot root; /nix is also a subvolume so the store persists.
{ inputs, ... }:
let
  diskId = "/dev/vda";
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  boot.tmp.cleanOnBoot = true;

  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        "size=4G"
        "mode=755"
      ];
    };
    disk = {
      main = {
        type = "disk";
        device = "${diskId}";
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
                name = "crypted";
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                settings = {
                  # TRIM leaks unused-block patterns on SSDs, which can
                  # reveal filesystem structure. Accepted trade-off for
                  # SSD longevity and performance.
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
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
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "subvol=home"
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/swap" = {
                      swap.swapfile.size = "12G";
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
  fileSystems."/persist".neededForBoot = true;
  fileSystems."/home".neededForBoot = true;
}
