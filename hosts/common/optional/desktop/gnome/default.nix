{ pkgs, ... }:
{
  # Enable dconf so it can be configured by home-manager.
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
      pkgs.cheese # webcam tool
      pkgs.gnome-music
      pkgs.epiphany # web browser
      pkgs.geary # email reader
      pkgs.gnome-characters
      pkgs.tali # poker game
      pkgs.iagno # go game
      pkgs.hitori # sudoku game
      pkgs.atomix # puzzle game
      pkgs.yelp # help viewer
      pkgs.gnome-contacts
      pkgs.gnome-initial-setup
    ];
    systemPackages = [
      pkgs.dconf-editor
      pkgs.gnome-tweaks
    ];
  };

  preservation = {
    preserveAt."/persist" = {
      directories = [
        "/var/lib/AccountsService"
      ];
    };
  };
}
