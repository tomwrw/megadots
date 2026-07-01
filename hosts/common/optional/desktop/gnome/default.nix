{ pkgs, ... }:
{
  programs = {
    # Enable dconf so it can be configured by home-manager.
    dconf.enable = true;
    # Let SSH (and thus git sk-signing/auth) prompt for the Token2 PIN via
    # a graphical dialog in non-tty contexts (e.g. GUI git clients).
    ssh.enableAskPassword = true;
    ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  };

  xdg.portal.enable = true;

  services = {
    libinput.enable = true;
    # gcr-ssh-agent hijacks FIDO2 sk keys; disable it so SSH talks to the
    # token directly.
    gnome.gcr-ssh-agent.enable = false;
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

  environment.persistence."/persist".directories = [
    "/var/lib/AccountsService"
  ];
}
