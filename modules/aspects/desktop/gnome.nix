_: {
  den.aspects.desktop.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        xdg.portal.enable = true;

        # avahi.openFirewall defaults to true upstream (same as openssh) - must
        # be explicit false, or its own default reopens 5353 globally alongside
        # the interface-scoped rule the firewall quirk produces.
        services.avahi.openFirewall = false;

        services = {
          libinput.enable = true;
          # gcr's agent handles sk-* (FIDO2) keys poorly, so the plain OpenSSH
          # agent is used instead - see core/ssh-agent.nix, which must be
          # included by any user who needs one. Turning this off without a
          # replacement previously left the fleet with no agent at all.
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
            pkgs.orca
          ];
          systemPackages = [
            pkgs.dconf-editor
            pkgs.gnome-tweaks
          ];
        };

        # Excluding orca above only stops GNOME enabling it (its module sets
        # services.orca.enable = notExcluded pkgs.orca); orca.nix separately
        # enables speechd itself when orca is on, so speechd still needs an
        # explicit off switch here. Plain assignment beats the mkDefault true
        # in nixos/modules/services/misc/graphical-desktop.nix — no mkForce
        # needed since nothing else sets it once orca is excluded.
        services.speechd.enable = false;
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
          # No color-scheme here: Stylix's gnome target already writes this key
          # from stylix.polarity, and neither side uses mkDefault. It only
          # evaluated because both happened to emit "prefer-dark" - flipping
          # polarity to "light" would have broken eval with a conflict.
          "org/gnome/desktop/interface" = {
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

    # mDNS. avahi is not enabled by anything of mine - the GNOME desktop module
    # pulls it in - so the port and the openFirewall suppression above belong
    # here, with the thing that causes them, rather than in core.networking.
    firewall.udp = [ 5353 ];

    persist.directories = [
      # Per-account desktop settings (language, session, avatar).
      "/var/lib/AccountsService"
      # colord and power-profiles-daemon are pulled in by the GNOME module,
      # not by hardware/, so their state belongs here. Without them, ICC
      # display profiles are lost and the power profile resets to balanced
      # on every boot.
      "/var/lib/colord"
      "/var/lib/power-profiles-daemon"
    ];
  };
}
