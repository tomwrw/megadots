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
