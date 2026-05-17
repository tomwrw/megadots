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
    gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gedit
      cheese # webcam tool
      gnome-music
      # text editor
      epiphany # web browser
      geary # email reader
      gnome-characters
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
      yelp # Help view
      gnome-contacts
      gnome-initial-setup
    ];
    systemPackages = with pkgs; [
      dconf-editor
      gnome-tweaks
    ];
    # This app/config requires the following persisted directories
    # and folders. Be This will only apply if impermanence is
    # enabled, and as soon as a user and host become out of
    # scope for this module, the items here will no longer
    # be persisted (they'll still exist in /persist thought).
    persistence."/persist" = {
      directories = [
        # Persisted directories go here (if needed).
        "/var/lib/AccountsService"
      ];
      files = [
        # Persisted files go here (if needed).
      ];
    };
  };
}
