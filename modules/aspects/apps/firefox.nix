{ inputs, ... }:
{
  flake-file.inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # This is NOT ~/.mozilla/firefox. Home Manager defaults configPath to the XDG
  # location for current Firefox, so profiles.ini, user.js, chrome/ (where
  # Stylix writes) and extensions/ all land here. Check it by evaluating
  # configPath, not by reading this file, which never sets it. Persisting
  # ~/.mozilla/firefox loses the real profile and leaves an empty legacy
  # directory that Firefox prefers, so it opens an unmanaged profile with no
  # theme and no add-ons. Did exactly that to myself once.
  # Firefox, themed through Stylix and with its profile directory persisted.
  den.aspects.firefox.persist.home.directories = [
    # The profile: cookies, history, container assignments and whatever the
    # extensions store. Home Manager rewrites its own half on activation, so
    # this is really for what Firefox writes at runtime, but they share a
    # directory.
    ".config/mozilla/firefox"
    # The HTTP and startup caches. The profile above keeps history and logins
    # across the rollback, but every page was still a cold fetch and every
    # start a cold start after a reboot.
    ".cache/mozilla"
  ];

  den.aspects.firefox.homeManager =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;
        policies = {
          AppAutoUpdate = false;
          BackgroundAppUpdate = false;
          DontCheckDefaultBrowser = true;
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableFirefoxScreenshots = true;
          DisableForgetButton = true;
          DisableMasterPasswordCreation = true;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "never";
          PasswordManagerEnabled = false;
          OfferToSaveLogins = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          OverrideFirstRunPage = "";
          PictureInPicture.Enabled = false;
          PromptForDownloadLocation = false;
          HardwareAcceleration = true;
          TranslateEnabled = true;
          Homepage.StartPage = "previous-session";
          UserMessaging = {
            UrlbarInterventions = false;
            SkipOnboarding = true;
          };
          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
          };
          EnableTrackingProtection = {
            Value = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          FirefoxHome = {
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
          };
          Handlers.schemes.vscode = {
            action = "useSystemDefault";
            ask = false;
          };
          Handlers.schemes.element = {
            action = "useSystemDefault";
            ask = false;
          };

          Preferences = {
            "browser.urlbar.suggest.searches" = true; # Need this for basic search suggestions
            "browser.urlbar.shortcuts.bookmarks" = false;
            "browser.urlbar.shortcuts.history" = false;
            "browser.urlbar.shortcuts.tabs" = false;
            "browser.urlbar.placeholderName" = "ddg";
            "browser.urlbar.placeholderName.private" = "ddg";
            "browser.aboutConfig.showWarning" = false; # No warning when going to config
            "browser.warnOnQuitShortcut" = false;
            "browser.tabs.loadInBackground" = true; # Load tabs automatically
            "media.ffmpeg.vaapi.enabled" = true; # Enable hardware acceleration
            "browser.in-content.dark-mode" = true; # Use dark mode
            # Only reaches pages without privacy.resistFingerprinting, which
            # forced prefers-color-scheme to light regardless - and capped
            # requestAnimationFrame at 60 Hz on a 144 Hz panel. The tracking
            # protection fingerprinting blocklist above is the part kept.
            "ui.systemUsesDarkTheme" = true;
            # No extensions.autoDisableScopes. It existed to auto-enable
            # add-ons dropped into the profile's extensions/ directory, which is
            # what profiles.<name>.extensions.packages does. globalExtensions
            # installs by policy instead, and a policy-installed add-on is
            # enabled by Firefox on sight - nothing sideloads into the profile
            # any more, so the pref had nothing left to act on.
            "extensions.update.enabled" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1; # Use new gtk file picker instead of legacy one
            "signon.management.page.breach-alerts.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
          };

          # No ExtensionSettings here. globalExtensions below generates it, one
          # entry per add-on, keyed by the addonId Home Manager reads out of the
          # package's passthru. Writing it by hand meant two lists to keep in
          # step - a package list and a block of add-on IDs copied off web pages -
          # and an ID that was wrong or stale failed silently, because a policy
          # entry for an add-on that isn't installed is simply inert.
        };

        # Installed by enterprise policy rather than into the profile, which is
        # what Home Manager's globalExtensions does: each entry becomes an
        # ExtensionSettings record with installation_mode = "force_installed" and
        # an install_url pointing at the XPI in the Nix store. Still pinned by
        # the firefox-addons input and still builds offline - nothing is fetched
        # from addons.mozilla.org - but the add-on IDs and the second list are
        # gone, and a policy-installed add-on needs no manual approval.
        #
        # force_installed also means these cannot be removed from about:addons.
        # That is the point of declaring them here; add
        # installation_mode = "normal_installed" to an entry's settings to get
        # the escape hatch back for that one.
        #
        # "global" is per-Firefox, not per-profile. Only 'default' exists below,
        # so there is nothing else for it to reach.
        globalExtensions =
          with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};
          let
            # Pinned to the toolbar and allowed in private windows. Every add-on
            # here wants both, so it is stated once.
            pinned = {
              default_area = "navbar";
              private_browsing = true;
            };
          in
          [
            {
              package = bitwarden;
              settings = pinned;
            }
            {
              package = proton-pass;
              settings = pinned;
            }
            {
              package = multi-account-containers;
              settings = pinned;
            }
            {
              package = ublock-origin;
              settings = pinned;
            }
          ];

        profiles.default = {
          isDefault = true;

          search = {
            force = true;
            default = "ddg";
            engines = {
              google.metaData.hidden = true;
              bing.metaData.hidden = true;
              ebay.metaData.hidden = true;
              amazondotcom-us.metaData.hidden = true;
              wikipedia.metaData.hidden = true;
            };
          };

          # No extensions.packages. See globalExtensions above - the add-ons are
          # installed by policy now, not symlinked into this profile.
        };
      };

      # Home Manager only writes mimeapps.list if xdg.mimeApps.enable is set,
      # so without this the defaults below do nothing. It used to work purely
      # because desktop/gnome.nix happens to enable it, which is an invisible
      # dependency on an unrelated aspect being there.
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/pdf" = [ "firefox.desktop" ];
      };
    };
}
