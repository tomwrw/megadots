_: {
  den.aspects.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        # git/ssh sign with the FIDO2 key by running ssh-keygen with a piped
        # stdin, so OpenSSH cannot prompt for the PIN inline and requires an
        # SSH_ASKPASS program (ssh-keygen.c, RP_ALLOW_STDIN). enableAskPassword
        # defaults to services.xserver.enable, which is false under Wayland
        # GNOME — so it must be set explicitly or SSH_ASKPASS stays empty and
        # signing dies with "ssh_askpass: exec(): No such file or directory".
        programs.ssh.enableAskPassword = true;
        programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

        xdg.portal.enable = true;

        services = {
          libinput.enable = true;
          # GNOME's ssh-agent advertises every key in ~/.ssh but can't do
          # FIDO2 ceremonies, so it hijacks and refuses sk-key operations
          # (ssh-keygen -Y sign consults the agent first). Our sk keys are
          # verify-required (PIN + touch per use), so an agent adds nothing.
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

    homeManager =
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
