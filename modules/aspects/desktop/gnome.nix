_: {
  # GNOME and GDM, the keyboard layout, and the state worth keeping across a
  # rollback.
  den.aspects.gnome = {
    nixos =
      { pkgs, ... }:
      {
        programs.dconf.enable = true;

        # A desktop setting rather than a locale one: GNOME reads it for the
        # session default input source, and a headless host has no use for it.
        services.xserver.xkb.layout = "gb";

        # No xdg.portal.enable or services.libinput.enable here, the GNOME
        # module already turns both on.

        # Defaults to true upstream, and its own default would reopen 5353 on
        # every interface alongside the LAN-scoped rule the firewall quirk makes.
        services.avahi.openFirewall = false;

        services = {
          # gcr handles FIDO2 keys badly, so apps/ssh.nix runs the plain
          # OpenSSH agent instead. Turning this off without putting something
          # back leaves no agent at all.
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

        # Excluding orca only stops GNOME enabling it; orca.nix turns on speechd
        # itself, so that needs switching off separately.
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
        # Not a persist.home entry, on purpose - see the comment on the two
        # units below.
        liveFile = "${config.home.homeDirectory}/.config/monitors.xml";
        savedFile = "/persist/home/${config.home.username}/.config/monitors.xml";
      in
      {
        # Installs each package and sets enabled-extensions from the same list,
        # so packages and UUIDs cannot drift apart.
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
          # No color-scheme here: Stylix writes that key from stylix.polarity,
          # and neither side uses mkDefault, so setting it too is a conflict.
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

        # Electron apps default to XWayland unless told otherwise, which loses
        # fractional scaling and leaves them blurry on HiDPI.
        home.sessionVariables.NIXOS_OZONE_WL = "1";

        xdg = {
          enable = true;
          mime.enable = true;
          mimeApps.enable = true;
        };

        # Display layout is the one piece of GNOME state impermanence cannot
        # hold, so it is copied in and out instead. mutter saves monitors.xml
        # with G_FILE_CREATE_REPLACE_DESTINATION - a temp file renamed over the
        # top - which defeats both forms impermanence has: rename onto a bind
        # mount is EBUSY, and the flag replaces a symlink with a plain file. A
        # persisted directory would work, but monitors.xml sits loose in
        # ~/.config.
        #
        # Activation rather than tmpfiles keeps this in the aspect that causes
        # the state, and is early enough: home-manager-<user>.service runs
        # Before=systemd-user-sessions.service.
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
          # default.target, not graphical-session.target: this only needs to be
          # watching by the time GNOME writes, and default.target is reached on
          # any login.
          Install.WantedBy = [ "default.target" ];
        };

        systemd.user.services.gnome-monitors-save = {
          Unit.Description = "Copy GNOME's saved display configuration to /persist";
          Service = {
            Type = "oneshot";
            # install -D makes the directory on the way past, and the user owns
            # their own /persist tree, so this needs no root.
            ExecStart = "${pkgs.coreutils}/bin/install -Dm644 ${liveFile} ${savedFile}";
          };
        };

      };

    # A sibling of the homeManager block above, not a key inside it: this aspect
    # is host scope, and the persist quirk is read in a user scope, so the data
    # takes the provides.to-users route.
    provides.to-users.persist.home.directories = [
      # The dconf database - window positions, per-app preferences, dash
      # favourites. Everything in dconf.settings above is rewritten on
      # activation; this is for the rest.
      ".config/dconf"
      # xdg-desktop-portal's permission store, where "Remember This Selection"
      # in a portal dialog is recorded. The path is a flatpak one because
      # xdg-permission-store hardcodes it. Without it sunshine re-prompts for
      # screen sharing on every login.
      ".local/share/flatpak/db"
      # gnome-keyring's secret store. Without it every boot starts with no
      # keyring and anything kept through libsecret is gone.
      ".local/share/keyrings"
    ];

    # mDNS, from the avahi the GNOME module pulls in - so the port and the
    # openFirewall override above belong here rather than in core.networking.
    firewall.udp = [ 5353 ];

    persist.system.directories = [
      # Per-account desktop settings (language, session, avatar).
      "/var/lib/AccountsService"

      # colord's home, so it carries its ownership. It is D-Bus activated rather
      # than a systemd service, so there is no StateDirectory to chown this on
      # the way past: a bare string is bind mounted root:root 0755 and the
      # daemon cannot write the ICC database this entry exists to preserve. Mode
      # matches users.users.colord.homeMode.
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "0700";
      }

      # The selected power profile, which otherwise resets to balanced every
      # boot, and per-device mount preferences for removable media. Both come
      # from the GNOME module rather than from anything here.
      "/var/lib/power-profiles-daemon"
      "/var/lib/udisks2"
    ];
  };
}
