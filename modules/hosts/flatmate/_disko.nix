# Disk configuration file for disko for the host 'spectre'.
# There are some specific configurations in this disko
# file that are needed for my impermanence setup to work.
# The primary btrfs volume needs to be labelled 'nixos'
# using the extraArgs = ["-L" "nixos" "-f"]; setting,
# and I also use a postCreateHook to generate a blank
# root snapshot when the host is first created.
{ ... }:
let
  diskId = "/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP";
in
{
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
                      swap.swapfile.size = "24G";
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
