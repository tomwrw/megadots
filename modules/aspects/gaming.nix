_: {
  den.aspects.gaming = {
    unfree = [
      "steam"
      "steam-unwrapped"
    ];

    nixos =
      { pkgs, ... }:
      {
        programs.steam = {
          enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
        programs.gamemode.enable = true;
        hardware.steam-hardware.enable = true;

        services.sunshine = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          settings = {
            origin_web_ui_allowed = "lan";
            system_tray = "disabled";
          };
        };

        environment.systemPackages = [ pkgs.game-devices-udev-rules ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mangohud
        ];
      };
  };
}
