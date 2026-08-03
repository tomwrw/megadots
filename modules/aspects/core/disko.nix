{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.disko =
    { host, ... }:
    {
      nixos = _: {
        imports = [ inputs.disko.nixosModules.disko ];

        boot.tmp.cleanOnBoot = true;

        disko.devices = {
          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "defaults"
              "size=${host.disk.tmpfsSize}"
              "mode=755"
            ];
          };
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

        fileSystems."/persist".neededForBoot = true;
        fileSystems."/home".neededForBoot = true;
      };
    };
}
