{ config, ... }:
{
  # Exposed so out-of-band tooling (my justfile) can read per-host data
  # (e.g. disk.id) without duplicating it or evaluating a full nixosConfiguration.
  flake.den.hosts = config.den.hosts;

  den.hosts.x86_64-linux = {
    endgame = {
      syncthing.id = "O5ZE76L-VFVTOEB-LBIKRRS-LNJKJTN-SOPSNTS-NMTNUHO-OOO453I-PXDOBAI";
      # channel left at its schema default ("latest").
      linux-kernel.optimization = "zen4";
      disk = {
        id = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606";
        swapSize = "48G";
      };
      # Verify via `ip -br addr` on host.
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
      network.lanInterface = "REPLACE_ME";
      users = {
        tomwrw = { };
      };
    };
  };
}
