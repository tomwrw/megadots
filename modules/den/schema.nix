{ lib, ... }:
{
  den.schema.host = {
    options.syncthing = {
      enable = lib.mkEnableOption "participation in the Syncthing mesh" // {
        default = true;
      };
      id = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "This host's Syncthing device ID (must match its provisioned cert).";
      };
    };

    options.disk = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Stable /dev/disk/by-id path of the system disk (no partition suffix).";
        example = "/dev/disk/by-id/nvme-Sabrent_SB-RKT5-2TB_48836385600606";
      };
      swapSize = lib.mkOption {
        type = lib.types.str;
        default = "8G";
        description = "btrfs swapfile size.";
      };
      tmpfsSize = lib.mkOption {
        type = lib.types.str;
        default = "4G";
        description = "Size of the tmpfs mounted at / (impermanence root).";
      };
    };

    options.linux-kernel = {
      channel = lib.mkOption {
        type = lib.types.enum [
          "lts"
          "latest"
        ];
        default = "latest";
        description = "CachyOS kernel release channel.";
      };
      optimization = lib.mkOption {
        type = lib.types.enum [
          "server"
          "generic"
          "zen4"
          "x86_64-v4"
        ];
        default = "generic";
        description = ''
          CachyOS kernel optimization target. "generic" builds an unoptimized
          (no -march) kernel that runs on any x86_64 CPU; the safe base default.
          "x86_64-v4" needs AVX-512 and "zen4" is AMD Zen 4 only.
        '';
      };
    };
  };

  den.schema.user.config.classes = lib.mkDefault [ "homeManager" ];
}
