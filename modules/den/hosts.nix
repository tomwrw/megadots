{ config, ... }:
{
  # Exposed so out-of-band tooling (the justfile) can read per-host data
  # (e.g. disk.id) without duplicating it or evaluating a full nixosConfiguration.
  flake.den.hosts = config.den.hosts;

  den.hosts.x86_64-linux = {
    endgame = {
      syncthing.id = "O5ZE76L-VFVTOEB-LBIKRRS-LNJKJTN-SOPSNTS-NMTNUHO-OOO453I-PXDOBAI";
      linux-kernel = {
        channel = "latest";
        optimization = "zen4";
      };
      disk = {
        id = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606";
        swapSize = "48G";
      };
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
      users = {
        tomwrw = { };
      };
    };
  };
}
