_: {
  # The COSMIC desktop and its greeter. No host takes it today - endgame moved
  # back to GNOME - so treat it as known-good rather than currently in use.
  #
  # There is no homeManager settings block because home-manager has no COSMIC
  # modules at all: every setting is made in the UI and written to
  # ~/.config/cosmic as RON. Persistence is therefore the whole mechanism by
  # which this desktop survives a boot, not a backstop for what declarative
  # config misses.
  den.aspects.cosmic = {
    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        xkb = config.services.xserver.xkb;
      in
      {
        services.desktopManager.cosmic.enable = true;
        services.desktopManager.cosmic.showExcludedPkgsWarning = false;
        services.displayManager.cosmic-greeter.enable = true;

        # A desktop setting, not a locale one: the COSMIC module reads
        # services.xserver.xkb.dir to export X11_BASE_RULES_XML for the session.
        services.xserver.xkb.layout = "gb";

        # avahi.openFirewall defaults to true upstream and the COSMIC module
        # turns avahi on, so without this its own default reopens 5353 on every
        # interface alongside the LAN-scoped rule the firewall quirk produces.
        services.avahi.openFirewall = false;

        # 'environment.cosmic', not 'services.desktopManager.cosmic' - the
        # exclusion list is a top-level option in nixpkgs.
        environment.cosmic.excludePackages = [
          # A screen reader I don't use, and it drags speechd in with it.
          pkgs.orca

          # The onboarding wizard, which reappears on every login and records
          # nothing anywhere, so there is no state to persist instead. Removing
          # the package removes its autostart .desktop with it.
          #
          # nixpkgs lists it in corePkgs ("ONLY ADD PACKAGES WITHOUT WHICH
          # COSMIC CRASHES"), so excluding it makes the module warn that COSMIC
          # may fail to start. It is plainly not that kind of package, hence
          # showExcludedPkgsWarning above - at the cost that a genuine future
          # core exclusion would also go unmentioned. Re-read this list if
          # COSMIC ever fails to come up after an update.
          pkgs.cosmic-initial-setup
        ];

        # Excluding orca stops COSMIC enabling it, but orca.nix turns on speechd
        # itself, so that needs switching off separately.
        services.speechd.enable = false;

        environment.systemPackages = [
          # COSMIC's own settings are RON, but the module still enables dconf
          # for GTK apps.
          pkgs.dconf-editor

          # A system-wide default keyboard layout, which neither nixpkgs nor
          # COSMIC derives from services.xserver.xkb.
          #
          # COSMIC reads each key from ~/.config/cosmic first, then falls back
          # to $XDG_DATA_DIRS/cosmic/<component>/v<n>/<key>. cosmic-settings
          # ships that directory but its only key is input_touchpad, so anything
          # without a user-level answer gets COSMIC's built-in "us". A session
          # is fine once cosmic-settings has written gb into the home; the
          # greeter is not, since it runs as its own user and cannot read a 0700
          # home - so the login prompt comes up in US and any password with a
          # layout-dependent character fails.
          #
          # Derived from services.xserver.xkb so the console, the session and
          # the greeter cannot disagree.
          (pkgs.writeTextFile {
            name = "cosmic-default-xkb-config";
            destination = "/share/cosmic/com.system76.CosmicComp/v1/xkb_config";
            text = ''
              (
                  rules: "",
                  model: "${xkb.model}",
                  layout: "${xkb.layout}",
                  variant: "${xkb.variant}",
                  options: ${if xkb.options == "" then "None" else ''Some("${xkb.options}")''},
                  repeat_delay: 600,
                  repeat_rate: 25,
              )
            '';
          })
        ];
      };

    provides.to-users.homeManager = _: {
      # Electron apps default to XWayland unless told otherwise, which loses
      # fractional scaling and leaves them blurry on HiDPI.
      home.sessionVariables.NIXOS_OZONE_WL = "1";

      xdg = {
        enable = true;
        mime.enable = true;
        mimeApps.enable = true;
      };
    };

    provides.to-users.persist.home.directories = [
      # Panel layout, applets, theme, shortcuts, workspaces, input settings.
      ".config/cosmic"

      # Display layout and refresh rate, which are NOT in .config/cosmic:
      # cosmic-comp writes them to .local/state/cosmic-comp/outputs.ron, keyed
      # by connector and EDID. Note 'cosmic-comp' and not 'cosmic' - the
      # compositor does not use the reverse-DNS id its own settings do, so
      # persisting .local/state/cosmic misses it and a 144Hz monitor is back at
      # 60 after a reboot.
      ".local/state/cosmic-comp"

      # The reverse-DNS half: wallpaper per output, last settings page, default
      # audio sink.
      ".local/state/cosmic"

      # GTK applications under COSMIC still read dconf, and the module enables
      # it (programs.dconf.packages = [ cosmic-session ]).
      ".config/dconf"

      # gnome-keyring's store, and xdg-desktop-portal's permission store - where
      # "Remember This Selection" in a portal dialog is recorded. The path is a
      # flatpak one because xdg-permission-store hardcodes it, not because
      # anything here is a flatpak. Without it sunshine re-prompts for screen
      # sharing on every login.
      ".local/share/keyrings"
      ".local/share/flatpak/db"
    ];

    # mDNS, from the avahi the COSMIC module turns on. Scoped to the LAN
    # interface by core.networking rather than by openFirewall.
    firewall.udp = [ 5353 ];

    persist.system.directories = [
      # Per-account desktop settings - language, session choice, and the avatar
      # the greeter draws.
      "/var/lib/AccountsService"

      # The greeter's home, and it has to carry its ownership. nixpkgs creates
      # the account with createHome and homeMode = "0750"; a bare string here is
      # bind mounted root:root 0755 over the top, the greeter cannot write its
      # own home, greetd hits its restart limit, and the machine boots to
      # nothing with only a VT to get back in. Mode matches nixpkgs' homeMode so
      # the two cannot disagree.
      {
        directory = "/var/lib/cosmic-greeter";
        user = "cosmic-greeter";
        group = "cosmic-greeter";
        mode = "0750";
      }

      # The selected power profile, which otherwise resets to balanced every
      # boot. No /var/lib/upower here even though COSMIC enables upower too -
      # core.impermanence already persists it, and impermanence asserts on a
      # path claimed twice.
      "/var/lib/power-profiles-daemon"

      # Per-device mount preferences for removable media; gvfs pulls udisks2 in.
      "/var/lib/udisks2"
    ];
  };
}
