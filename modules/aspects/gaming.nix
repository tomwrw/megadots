{ ... }:
{
  den.aspects.gaming = {
    nixos =
      { pkgs, ... }:
      {
        programs.steam = {
          enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
        };
        programs.gamemode.enable = true;
        hardware.steam-hardware.enable = true;

        services.udev.packages = [ pkgs.sunshine ];
        services.sunshine = {
          enable = true;
          autoStart = true;
          capSysAdmin = true;
          openFirewall = true;
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
