_: {
  megadots.desktop.cosmic = {
    description = "The COSMIC desktop and its greeter, with the whole of ~/.config/cosmic kept across a rollback.";

    nixos =
      { pkgs, ... }:
      {
        services.desktopManager.cosmic.enable = true;
        services.displayManager.cosmic-greeter.enable = true;

        # British layout. Same reasoning as desktop/gnome.nix: it is a desktop
        # setting, not a locale one, and the COSMIC module reads
        # services.xserver.xkb.dir to export X11_BASE_RULES_XML for the session.
        services.xserver.xkb.layout = "gb";

        # avahi.openFirewall defaults to true upstream and the COSMIC module
        # turns avahi on with mkDefault, so without this its own default
        # reopens 5353 on every interface alongside the LAN-scoped rule the
        # firewall quirk produces.
        services.avahi.openFirewall = false;

        # 'environment.cosmic', not 'services.desktopManager.cosmic' - the
        # exclusion list is a top-level option in nixpkgs, unlike GNOME's
        # environment.gnome.excludePackages which at least sits under a similar
        # name. Excluding a package the module calls "core" prints a warning
        # unless showExcludedPkgsWarning is off; none of these are core.
        environment.cosmic.excludePackages = [
          # A screen reader I don't use, and it drags speechd in with it.
          pkgs.orca
        ];

        # Excluding orca stops COSMIC enabling it, but orca.nix turns on speechd
        # itself, so that needs switching off separately. Same dance as
        # desktop/gnome.nix.
        services.speechd.enable = false;

        environment.systemPackages = [
          # COSMIC has no dconf editor of its own and its own settings are RON
          # files, but dconf is still enabled by the module for GTK apps, so
          # this stays useful for the same reasons it is under GNOME.
          pkgs.dconf-editor
        ];
      };

    provides.to-users.homeManager = _: {
      # Electron apps default to XWayland unless told otherwise, which loses
      # fractional scaling and leaves them blurry on HiDPI. Set once here rather
      # than per app; about a dozen of mine are Electron.
      home.sessionVariables.NIXOS_OZONE_WL = "1";

      xdg = {
        enable = true;
        mime.enable = true;
        mimeApps.enable = true;
      };
    };

    # No homeManager settings block, and that is not an oversight: home-manager
    # has no COSMIC modules at all in the version this flake pins - nothing
    # under modules/ matches "cosmic", so there is no programs.cosmic-* or
    # dconf-equivalent to write. Every COSMIC setting is made in the UI and
    # written to ~/.config/cosmic as RON, which makes persistence the entire
    # mechanism by which my configuration survives rather than a backstop for
    # the bits declarative config misses.
    #
    # That is a real difference from desktop/gnome.nix, where dconf.settings
    # carries the important choices and persistence only catches the rest. Here
    # the rollback is the only thing standing between me and a default desktop
    # every boot.
    provides.to-users.home-persist.directories = [
      # Everything COSMIC knows about how I like it: panel layout and applets,
      # theme, shortcuts, workspaces, input settings, and the display layout in
      # com.system76.CosmicComp/v1/outputs.
      #
      # Worth noting against the GNOME aspect next door, which needs a pair of
      # systemd units to shuttle ~/.config/monitors.xml in and out: mutter
      # writes that file by rename, which defeats both an impermanence file
      # entry and a symlink, and it sits loose in ~/.config where a directory
      # entry would be far too broad. COSMIC keeps the equivalent state inside
      # its own directory, so persisting the directory covers it and none of
      # that machinery is needed.
      ".config/cosmic"

      # GTK applications under COSMIC still read dconf, and the COSMIC module
      # enables it (programs.dconf.packages = [ cosmic-session ]). This is also
      # what keeps the host-scope canary in checks.nix meaningful on a machine
      # with no GNOME.
      ".config/dconf"

      # xdg-desktop-portal's permission store - where "Remember This Selection"
      # in a portal dialog is recorded. The path is a flatpak one because
      # xdg-permission-store hardcodes it, not because anything here is a
      # flatpak. Without it sunshine re-prompts for screen sharing on every
      # login, since the portal has forgotten the grant even though sunshine
      # still holds its restore token in .config/sunshine.
      ".local/share/keyrings"
      ".local/share/flatpak/db"
    ];

    # mDNS, from the avahi the COSMIC module turns on. Declared here next to
    # the thing that causes it, and scoped to the LAN interface by
    # core.networking's firewall quirk consumer rather than by openFirewall.
    firewall.udp = [ 5353 ];

    persist.directories = [
      # Per-account desktop settings - language, session choice, and the avatar
      # the greeter draws. accounts-daemon is enabled by both the desktop and
      # the greeter module.
      "/var/lib/AccountsService"

      # The greeter's own home, and it has to carry its ownership.
      #
      # cosmic-greeter runs as its own system user, and nixpkgs creates that
      # account with home = /var/lib/cosmic-greeter, createHome = true and
      # homeMode = "0750". A bare string here means impermanence bind mounts a
      # root:root 0755 directory over the top, so the greeter cannot write to
      # its own home. It exits immediately, greetd logs "greeter exited without
      # creating a session", restarts five times and gives up - leaving a
      # machine that boots to nothing, with the only way in being a VT and
      # 'cosmic-session' by hand. Which is exactly what happened.
      #
      # The mode matches nixpkgs' homeMode rather than being picked here, so
      # the two cannot disagree.
      {
        directory = "/var/lib/cosmic-greeter";
        user = "cosmic-greeter";
        group = "cosmic-greeter";
        mode = "0750";
      }

      # power-profiles-daemon's selected profile, which otherwise resets to
      # balanced on every boot. It is enabled by the COSMIC module rather than
      # by anything of mine, so its state belongs to this aspect.
      #
      # No /var/lib/upower here even though COSMIC enables upower too:
      # core.impermanence already persists it for every host. impermanence
      # asserts on a path claimed twice, so the duplicate is an eval error
      # rather than something to notice later - which is how I found it.
      "/var/lib/power-profiles-daemon"

      # Per-device mount preferences for removable media. udisks2 is not named
      # anywhere in the COSMIC module; gvfs pulls it in, so it is on here just
      # as it is under GNOME. Checked rather than assumed - services.udisks2
      # evaluates true on this host.
      "/var/lib/udisks2"
    ];
  };
}
