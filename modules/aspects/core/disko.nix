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
                      # Everything must go through `settings`, not
                      # `extraOpenArgs`: disko passes settings straight to
                      # boot.initrd.luks.devices.<name>, whereas extraOpenArgs
                      # is only used by its install-time `cryptsetup open`. The
                      # perf flags used to live there and so were applied
                      # exactly once, during nixos-anywhere, and never again at
                      # boot - the generated crypttab read `crypted <dev> - discard`.
                      settings = {
                        # TRIM leaks unused-block patterns on SSDs, which can
                        # reveal filesystem structure. Accepted trade-off for
                        # SSD longevity and performance.
                        allowDiscards = true;
                        # Skip dm-crypt's read/write queues. On NVMe the queues
                        # cost more in latency than they buy in throughput.
                        bypassWorkqueues = true;
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
