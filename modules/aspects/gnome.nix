_: {
  den.aspects.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        xdg.portal.enable = true;

        services = {
          libinput.enable = true;
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

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.gnomeExtensions.appindicator
          pkgs.gnomeExtensions.user-themes
        ];

        dconf.settings = {
          # Don't try to suspend while on AC.
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            show-battery-percentage = true;
            enable-hot-corners = true;
          };
          # Window controls: minimise/maximise/close.
          "org/gnome/desktop/wm/preferences".button-layout = ":appmenu,minimize,maximize,close";
          "org/gnome/mutter" = {
            edge-tiling = true;
            dynamic-workspaces = true;
          };
          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
            natural-scroll = true;
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              pkgs.gnomeExtensions.appindicator.extensionUuid
              pkgs.gnomeExtensions.user-themes.extensionUuid
            ];
          };
        };

        xdg = {
          enable = true;
          mime.enable = true;
          mimeApps.enable = true;
        };
      };

    persist.directories = [ "/var/lib/AccountsService" ];
  };
}
