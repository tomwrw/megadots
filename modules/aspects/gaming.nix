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

        # Sunshine game-streaming host. capSysAdmin is currently required for
        # Wayland capture (see LizardByte/Sunshine#4417 — removable once their
        # XDG-portal capture lands). openFirewall opens its ports natively.
        services.udev.packages = [ pkgs.sunshine ];
        services.sunshine = {
          enable = true;
          autoStart = true;
          capSysAdmin = true;
          openFirewall = true;
        };

        environment.systemPackages = [ pkgs.game-devices-udev-rules ];
        # (32-bit graphics is provided by the `graphics` aspect.)
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
