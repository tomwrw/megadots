{
  config,
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
    "org/gnome/desktop/wm/preferences" = {
      resize-with-right-button = true;
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
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
        "firefox.desktop"
        "codium.desktop"
        "obsidian.desktop"
        "syncthing-ui.desktop"
        "virt-manager.desktop"
        "spotify.desktop"
        "element-desktop.desktop"
        "vesktop.desktop"
        "com.github.xeco23.WasIstLos.desktop"
        "signal.desktop"
      ];
      last-selected-power-profile = "performance";
    };
    "org/gnome/desktop/applications/terminal" = {
      exec = "ghostty";
      exec-arg = "";
    };
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>q" ];
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Terminal";
      command = "ghostty";
      binding = "<Super>Return";
    };
  };
  # Set XDG config for things like known directories and custom dirs.
  # Without this, nautilus won't show the bookmarks in the sidebar.
  xdg = {
    enable = true;
    mime.enable = true;
    mimeApps.enable = true;
    # Nautilus sidebar bookmarks.
    configFile."gtk-3.0/bookmarks".text = ''
      file://${config.xdg.userDirs.download} Downloads
      file://${config.xdg.userDirs.documents} Documents
      file://${config.xdg.userDirs.pictures} Pictures
      file://${config.xdg.userDirs.videos} Videos
      file://${config.xdg.userDirs.music} Music
      file://${config.home.homeDirectory}/Sync Sync
      file://${config.home.homeDirectory}/Development Development
    '';
    userDirs = {
      enable = true;
      createDirectories = true;
      music = "${config.home.homeDirectory}/Music";
      videos = "${config.home.homeDirectory}/Videos";
      pictures = "${config.home.homeDirectory}/Pictures";
      templates = "${config.home.homeDirectory}/Documents/Templates";
      download = "${config.home.homeDirectory}/Downloads";
      documents = "${config.home.homeDirectory}/Documents";
      desktop = "${config.home.homeDirectory}/Desktop";
      # I don't need the public share.
      publicShare = null;
      setSessionVariables = false;
    };
  };
}
