{ lib, ... }:
{
  # Syncthing peers this config doesn't build. They can't live in den.hosts,
  # which describes whole machines and turns each entry into a
  # nixosConfiguration; the TrueNAS box is just a device ID to trust, paired by
  # hand in its own GUI.
  #
  # Declared here rather than in the syncthing aspect because this is roster
  # data - which machines I own and how they find each other. quirks.nix
  # appends what's here onto the peer pipe.
  options.fleet.externalPeers = lib.mkOption {
    default = { };
    description = "Syncthing peers outside the den fleet, keyed by device name.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "The peer's Syncthing device ID.";
          };
          addresses = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              Explicit addresses, for a peer local discovery can't find. Left
              empty, Syncthing falls back to its own "dynamic" default.
            '';
          };
        };
      }
    );
  };

  config = {
    # Addresses are pinned rather than left dynamic. Relays and global discovery
    # are off, so the only thing that could locate a peer is a local announce on
    # 21027, and an appliance running Syncthing in a container often can't
    # broadcast onto the LAN at all.
    fleet.externalPeers = {
      nas = {
        # TrueNAS Syncthing GUI: Actions > Show ID.
        id = "F7JXVJN-DXADY4D-OGQGPUG-ENDQEDW-5PROBMK-E37HIYE-6OJ4HKW-25W4YQX";
        addresses = [ "tcp://syncthing.extranet.casa:20978" ];
      };
    };

    den.hosts.x86_64-linux = {
      endgame = {
        syncthing.id = "O5ZE76L-VFVTOEB-LBIKRRS-LNJKJTN-SOPSNTS-NMTNUHO-OOO453I-PXDOBAI";
        linux-kernel.variant = "lto-znver4";
        disk = {
          id = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606";
          swapSize = "48G";
        };
        # Verify via 'ip -br addr' on host.
        network.lanInterface = "enp8s0";
        users.tomwrw = { };
      };

      flatmate = {
        syncthing.id = "PSSB5YD-TVF4BXM-RH4E5DY-NZYON6Y-LKBBBGL-HHNIB2T-K6QRHIM-FTHKUAF";
        disk = {
          id = "/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP";
          swapSize = "24G";
        };
        # Verify via 'ip -br addr' on host.
        network.lanInterface = "wlp0s20f3";
        users.tomwrw = { };
      };
    };
  };
}
