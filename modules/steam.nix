{
  nixpkgs.config.allowUnfreePackages = [
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
    "steam-runtime"
    "proton-ge-bin"
    "steamdeck-hw-theme"
  ];

  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          gamescope = prev.gamescope.overrideAttrs (_: {
            # https://github.com/ValveSoftware/gamescope/issues/1924#issuecomment-3725667842
            NIX_CFLAGS_COMPILE = [ "-fno-fast-math" ];
          });
        })
      ];

      services.udev.packages = [ pkgs.sunshine ];
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };

      hardware.steam-hardware.enable = true;

      programs = {
        gamemode.enable = true;
        steam = {
          enable = true;
          gamescopeSession.enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
          extraPackages = [ pkgs.gamemode ];
        };
      };

      environment.systemPackages = with pkgs; [
        game-devices-udev-rules
      ];

      boot.kernel.sysctl = {
        "kernel.sched_cfs_bandwidth_slice_us" = 3000;
        "net.ipv4.tcp_fin_timeout" = 5;
        "kernel.split_lock_mitigate" = 0;
        "vm.max_map_count" = 2147483642;
      };
    };

  flake.modules.homeManager.gaming = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;
    };
  };
}
