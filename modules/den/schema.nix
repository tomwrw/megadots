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
    };

    options.network = {
      lanInterface = lib.mkOption {
        type = lib.types.str;
        description = "Primary LAN interface name, for scoping firewall rules to the local network.";
        example = "enp8s0";
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

  # The load-bearing line in this file, and the one with no error to guide you
  # if it goes wrong. Every user gets both classes:
  #
  # - "homeManager" is the only thing that activates den's home-manager
  #   battery. Narrow this list and every user's Home Manager config stops
  #   being built, silently - no eval error, just a system with none of it.
  # - "user" is the NixOS-side class. It's what makes the `user` block in
  #   users/tomwrw/tomwrw.nix apply, which is where the account itself and its
  #   hashedPasswordFile come from.
  #
  # mkDefault so an individual user can still narrow it - a service account
  # with no home would set classes = [ "user" ].
  den.schema.user.config.classes = lib.mkDefault [
    "homeManager"
    "user"
  ];
}
