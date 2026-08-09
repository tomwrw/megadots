_: {
  den.aspects.desktop.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        # No xdg.portal.enable or services.libinput.enable here, the GNOME
        # module already turns both on.

        # avahi.openFirewall defaults to true upstream, same as openssh, so it
        # needs an explicit false or its own default reopens 5353 everywhere
        # alongside the interface-scoped rule from the firewall quirk.
        services.avahi.openFirewall = false;

        services = {
          # gcr's agent handles FIDO2 keys badly, so I use the plain OpenSSH
          # agent instead. See core/security/ssh-agent.nix, which any user
          # needing an agent has to include. Turning this off without putting
          # something back left me with no agent at all last time.
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

        # Excluding orca above only stops GNOME enabling it. orca.nix turns on
        # speechd itself when orca is on, so speechd still needs switching off
        # here. Plain assignment beats the mkDefault true upstream, and no
        # mkForce is needed since nothing else sets it once orca is gone.
        services.speechd.enable = false;
      };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # Where the copies live. Not a home.persistence entry, on purpose -
        # see the comment on the two units below.
        liveFile = "${config.home.homeDirectory}/.config/monitors.xml";
        savedFile = "/persist/home/${config.home.username}/.config/monitors.xml";
      in
      {
        # programs.gnome-shell does what I was doing by hand: installs each
        # extension's package and sets disable-user-extensions = false plus
        # enabled-extensions from the same list, so the packages and the UUIDs
        # can't drift apart any more.
        programs.gnome-shell = {
          enable = true;
          extensions = [
            { package = pkgs.gnomeExtensions.appindicator; }
            { package = pkgs.gnomeExtensions.user-themes; }
          ];
        };

        dconf.settings = {
          # Don't try to suspend while on AC.
          "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
          # No color-scheme here. Stylix's gnome target already writes that key
          # from stylix.polarity and neither side uses mkDefault, so it only
          # evaluated because both happened to say "prefer-dark". Switching
          # polarity to light would have broken eval with a conflict.
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
        };

        # I'm on Wayland, but Electron apps default to XWayland unless told
        # otherwise, which loses fractional scaling and leaves them blurry on
        # HiDPI. The Surface especially. About a dozen apps I use are Electron,
        # so set it once here instead of per app.
        home.sessionVariables.NIXOS_OZONE_WL = "1";

        xdg = {
          enable = true;
          mime.enable = true;
          mimeApps.enable = true;
        };

        # Display settings - resolution, refresh rate, monitor layout - are
        # the one piece of GNOME state impermanence can't hold as a
        # home.persistence entry, so they get copied in and out instead.
        #
        # mutter saves ~/.config/monitors.xml with
        # G_FILE_CREATE_REPLACE_DESTINATION: it writes a temp file beside it
        # and renames over the top. That defeats both forms impermanence has.
        # A file entry is a bind mount, and rename onto a mount point is
        # EBUSY, which surfaces as "Saving monitor configuration failed" and a
        # revert once the confirmation dialog times out. A symlink fares no
        # better - the flag means "replace, don't follow links", so the
        # symlink is swapped for a plain file and the next boot loses it. Only
        # a persisted directory would work, and monitors.xml sits directly in
        # ~/.config, which every app aspect persists a subdirectory of.
        #
        # Restoring from activation rather than a tmpfiles rule keeps this
        # inside the aspect that causes the state, and is still early enough:
        # home-manager-<user>.service is ordered
        # Before=systemd-user-sessions.service, so it has run before a login
        # is possible, let alone before gnome-shell reads the file.
        home.activation.restoreGnomeMonitors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Only when the live file is missing, so a 'nixos-rebuild switch'
          # mid-session doesn't roll back a layout I haven't logged out of.
          if [ ! -e ${lib.escapeShellArg liveFile} ] && [ -e ${lib.escapeShellArg savedFile} ]; then
            run ${pkgs.coreutils}/bin/install -Dm644 \
              ${lib.escapeShellArg savedFile} ${lib.escapeShellArg liveFile}
          fi
        '';

        # The other half: catch whatever GNOME writes. PathChanged fires on a
        # file moved into place, which is exactly the rename above.
        systemd.user.paths.gnome-monitors-save = {
          Unit.Description = "Watch GNOME's saved display configuration";
          Path.PathChanged = liveFile;
          # default.target and not graphical-session.target. This only needs
          # to be watching by the time GNOME writes, and default.target is
          # reached on any login without depending on the session manager
          # having wired graphical-session.target up.
          Install.WantedBy = [ "default.target" ];
        };

        systemd.user.services.gnome-monitors-save = {
          Unit.Description = "Copy GNOME's saved display configuration to /persist";
          Service = {
            Type = "oneshot";
            # install -D makes /persist/home/<user>/.config on the way past.
            # The user owns their own /persist tree, so this needs no root.
            ExecStart = "${pkgs.coreutils}/bin/install -Dm644 ${liveFile} ${savedFile}";
          };
        };

        home.persistence."/persist".directories = [
          # The dconf database. Everything set above is rewritten on
          # activation, so this is for the rest: window positions, per-app
          # preferences, the dash favourites, anything I changed in Settings
          # instead of in this file.
          ".config/dconf"
          # gnome-keyring's secret store. The GNOME module runs the daemon, so
          # without this every boot starts with no keyring, GNOME asks me to
          # make one, and anything stored through libsecret is gone.
          ".local/share/keyrings"
        ];
      };

    # mDNS. I never enable avahi myself, the GNOME desktop module pulls it in,
    # so the port and the openFirewall override above belong here next to the
    # thing causing them and not in core.networking.
    firewall.udp = [ 5353 ];

    persist.directories = [
      # Per-account desktop settings (language, session, avatar).
      "/var/lib/AccountsService"
      # colord and power-profiles-daemon come from the GNOME module rather
      # than hardware/, so their state belongs here. Without them I lose ICC
      # display profiles and the power profile resets to balanced every boot.
      "/var/lib/colord"
      "/var/lib/power-profiles-daemon"
      # Same story, udisks2 is turned on by the GNOME desktop module and not
      # by me. Holds per-device mount preferences for removable media.
      "/var/lib/udisks2"
    ];
  };
}
