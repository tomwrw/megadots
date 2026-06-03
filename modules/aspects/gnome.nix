{ ... }:
{
  den.aspects.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        xdg.portal.enable = true;

        services = {
          libinput.enable = true;
          desktopManager.gnome = {
            enable = true;
          };
          displayManager.gdm = {
            enable = true;
            autoSuspend = false;
          };
        };

        environment = {
          gnome.excludePackages = [
            pkgs.gnome-photos
            pkgs.gnome-tour
            pkgs.gedit
            pkgs.cheese
            pkgs.gnome-music
            pkgs.epiphany
            pkgs.geary
            pkgs.tali
            pkgs.iagno
            pkgs.hitori
            pkgs.atomix
            pkgs.yelp
            pkgs.gnome-contacts
            pkgs.gnome-initial-setup
          ];
          systemPackages = [
            pkgs.dconf-editor
            pkgs.gnome-tweaks
          ];
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.gnomeExtensions.appindicator
          pkgs.gnomeExtensions.user-themes
        ];
      };
  };
}
