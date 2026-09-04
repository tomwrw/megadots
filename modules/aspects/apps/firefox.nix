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
  den.aspects.firefox.persist.home.directories = [ ".config/mozilla/firefox" ];

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
            "ui.systemUsesDarkTheme" = true;
            "extensions.autoDisableScopes" = 0; # Automatically enable extensions
            "extensions.update.enabled" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1; # Use new gtk file picker instead of legacy one
            "signon.management.page.breach-alerts.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
            "privacy.resistFingerprinting" = true;
          };

          # Configure extension behavior (toolbar pinning, etc.).
          ExtensionSettings = {
            # ProtonPass - pin to toolbar.
            "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
              installation_mode = "normal_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            # uBlock Origin - pin to toolbar.
            "uBlock0@raymondhill.net" = {
              installation_mode = "normal_installed";
              default_area = "navbar";
              private_browsing = true;
            };
            # Multi-Account Containers - pin to toolbar
            "@testpilot-containers" = {
              installation_mode = "normal_installed";
              default_area = "navbar";
              private_browsing = true;
            };
          };
        };

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

          # Extensions from firefox-addons, which is safer than the xpi
          # method I used before.
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            proton-pass
            multi-account-containers
            ublock-origin
          ];
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

      # The profile: cookies, history, container assignments and whatever the
      # extensions store. Home Manager rewrites its own half on activation, so
      # this is really for what Firefox writes at runtime, but they share a
      # directory.
      #
    };
}
