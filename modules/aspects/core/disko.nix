{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.disko =
    { host, ... }:
    let
      # The name disko gives the opened LUKS mapping below. Bound once so the
      # postCreateHook and the 'content.name' cannot drift apart.
      luksName = "crypted";
    in
    {
      nixos = _: {
        imports = [ inputs.disko.nixosModules.disko ];

        # No boot.tmp.cleanOnBoot: / is restored from a blank snapshot on every
        # boot (core.ephemeral-btrfs), so /tmp is already empty by the time
        # anything could clean it.

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
                      # Everything must go through 'settings', not
                      # 'extraOpenArgs': disko passes settings straight to
                      # boot.initrd.luks.devices.<name>, whereas extraOpenArgs
                      # is only used by its install-time 'cryptsetup open'. The
                      # perf flags used to live there and so were applied
                      # exactly once, during nixos-anywhere, and never again at
                      # boot - the generated crypttab read 'crypted <dev> - discard'.
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

                        # Snapshot the volume read-only while it is still empty.
                        # core.ephemeral-btrfs restores this on every boot, so it
                        # has to be taken here, at format time - a snapshot taken
                        # any later already contains the installed system.
                        postCreateHook = ''
                          mount -t btrfs /dev/mapper/${luksName} /mnt
                          btrfs subvolume snapshot -r /mnt /mnt/root-blank
                          umount /mnt
                        '';

                        subvolumes = {
                          # Rolled back to root-blank on every boot. /home lives
                          # inside it deliberately: user state is opt-in through
                          # home.persistence, the same way system state is opt-in
                          # through core.impermanence.
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

        # impermanence asserts this itself, but state it here too: this is where
        # the mount is declared, and activation reads the sops age key from
        # /persist before systemd starts.
        fileSystems."/persist".neededForBoot = true;
      };
    };
}
