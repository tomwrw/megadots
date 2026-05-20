{
  pkgs,
  ...
}:
{
  imports = [
    ../common
  ];

  home = {
    packages = with pkgs; [
      gnomeExtensions.appindicator
      gnomeExtensions.user-themes
    ];
  };
  dconf.settings = {
    # Don't try to suspend while plugged in.
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
    };
    "org/gnome/desktop/interface" = {
      # gtk4 theme/scheme.
      color-scheme = "prefer-dark";
      # accent-color = "slate";
      show-battery-percentage = true;
    };
    # Enable minimise, maximise buttons.
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":appmenu,minimize,maximize,close";
    };
    # Wayland Mutter tweaks.
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
    };
    "org/gnome/desktop/interface" = {
      enable-hot-corners = true;
    };
    # Touchpad support and config.
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      natural-scroll = true;
    };
    # Extension config.
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = with pkgs.gnomeExtensions; [
        appindicator.extensionUuid
        user-themes.extensionUuid
      ];
    };
  };
  # Set XDG config for things like known directories and custom dirs.
  # Without this, nautilus won't show the bookmarks in the sidebar.
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
  };
}
