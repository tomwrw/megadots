# Disk configuration file for disko for the host 'flatmate'.
# There are some specific configurations in this disko
# file that are needed for my impermanence setup to work.
# The primary btrfs volume needs to be labelled 'nixos'
# using the extraArgs = ["-L" "nixos" "-f"]; setting,
# and I also use a postCreateHook to generate a blank
# root snapshot when the host is first created.
{ inputs, ... }:
let
  diskId = "/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP";
in
{
  imports = [
    inputs.disko.nixosModules.disko
  ];
  disko.devices = {
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
                # These options can improve performance on NVMe drives by adjusting
                # how LUKS handles I/O operations. They are not essential but can
                # provide a noticeable boost in disk speed.
                extraOpenArgs = [
                  "--allow-discards"
                  "--perf-no_read_workqueue"
                  "--perf-no_write_workqueue"
                ];
                settings = {
                  # Security consideration:
                  # TRIM/discard operations on SSDs can leak information about
                  # which blocks are unused, potentially revealing filesystem
                  # structure or metadata patterns. This is a common compromise
                  # for SSD performance and longevity. The risk is generally
                  #  acceptable for me but worth documenting. See the above
                  # --allow-discards extraOptionArgs too.
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
}
