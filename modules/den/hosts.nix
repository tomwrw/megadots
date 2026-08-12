{ config, lib, ... }:
{
  # Exposed so my justfile can read per-host data like disk.id without
  # duplicating it or evaluating a whole nixosConfiguration.
  #
  # Not serialisable. The host submodule carries den's resolved aspect
  # functors, so 'nix eval --json' on it fails. Fine in 'nix repl' or for a
  # single leaf with --raw, but anything wanting JSON should read the roster
  # below.
  flake.den.hosts = config.den.hosts;

  # The same roster narrowed to plain scalars, which is what my justfile and
  # the flake checks actually read. Listing the fields by hand means adding a
  # schema option never quietly changes what tooling sees.
  flake.roster = lib.mapAttrs (
    _: hosts:
    lib.mapAttrs (_: host: {
      inherit (host.disk) id swapSize;
      lanInterface = host.network.lanInterface;
      syncthing = { inherit (host.syncthing) enable id; };
    }) hosts
  ) config.den.hosts;

  # Syncthing peers this config doesn't build. They can't live in den.hosts,
  # which describes whole machines - disk, LAN interface, users - and turns
  # each entry into a nixosConfiguration. The TrueNAS box is just a device ID
  # to trust, and the other half of the pairing is done by hand in its own
  # Syncthing GUI.
  #
  # Here rather than in apps/sync/syncthing.nix because this is roster data:
  # which machines I own and how they find each other. That aspect implements
  # syncthing and should be as portable as any other; it had my NAS baked into
  # it, which made it the one app aspect nobody else could reuse. den/mesh.nix
  # declares this option and appends what's here onto the peer pipe.
  #
  # Addresses are pinned rather than left dynamic. Relays and global discovery
  # are off, so the only thing that could locate a peer is a local announce on
  # 21027, and an appliance running Syncthing in a container often can't
  # broadcast onto the LAN at all. A static lease on the NAS makes this the
  # more reliable half of the trade. See the README on why it is an IP.
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
      # channel left at its schema default ("latest").
      linux-kernel.optimization = "zen4";
      disk = {
        id = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606";
        swapSize = "48G";
      };
      # Verify via 'ip -br addr' on host.
      network.lanInterface = "enp8s0";
      users = {
        tomwrw = { };
      };
    };

    flatmate = {
      syncthing.id = "PSSB5YD-TVF4BXM-RH4E5DY-NZYON6Y-LKBBBGL-HHNIB2T-K6QRHIM-FTHKUAF";
      disk = {
        id = "/dev/disk/by-id/nvme-KBG40ZPZ512G_TOSHIBA_MEMORY_89R201INNLAP";
        swapSize = "24G";
      };
      # Verify via 'ip -br addr' on host.
      network.lanInterface = "wlp0s20f3";
      users = {
        tomwrw = { };
      };
    };
  };
}
