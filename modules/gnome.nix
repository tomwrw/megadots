{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {
      services.displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      services.desktopManager.gnome.enable = true;

      environment.systemPackages = with pkgs; [
        dconf-editor
        gnome-tweaks
      ];

      environment.gnome.excludePackages = with pkgs; [
        atomix
        cheese
        epiphany
        geary
        gedit
        gnome-characters
        gnome-contacts
        gnome-initial-setup
        gnome-music
        gnome-photos
        gnome-tour
        hitori
        iagno
        tali
        yelp
      ];
    };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        gnomeExtensions.appindicator
        gnomeExtensions.user-themes
      ];

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          show-battery-percentage = true;
          enable-hot-corners = true;
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = ":appmenu,minimize,maximize,close";
          resize-with-right-button = true;
        };

        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>q" ];
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          natural-scroll = true;
        };

        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
        };

        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = with pkgs.gnomeExtensions; [
            appindicator.extensionUuid
            user-themes.extensionUuid
          ];
          last-selected-power-profile = "performance";
        };
      };
    };
}
