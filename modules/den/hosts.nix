{ config, lib, ... }:
{
  # Exposed so out-of-band tooling (my justfile) can read per-host data
  # (e.g. disk.id) without duplicating it or evaluating a full nixosConfiguration.
  #
  # NOTE: this is NOT serialisable - the host submodule carries den's resolved
  # aspect functors, so 'nix eval --json .#den.hosts' fails with "cannot convert
  # a function to JSON". Fine for 'nix repl' and for reading a single leaf with
  # 'nix eval --raw', but anything that needs JSON must read 'flake.roster' below.
  flake.den.hosts = config.den.hosts;

  # A narrowed, JSON-safe projection of the roster: plain scalars only. This is
  # the tooling contract (justfile recipes, flake checks) - keeping it explicit
  # means adding a schema option never silently changes what tooling sees.
  flake.roster = lib.mapAttrs (
    _: hosts:
    lib.mapAttrs (_: host: {
      inherit (host.disk) id swapSize tmpfsSize;
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
