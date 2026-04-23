{ inputs, ... }:
{
  flake-file.inputs = {
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      programs.firefox = {
        enable = true;

        policies = {
          DontCheckDefaultBrowser = true;
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableFirefoxScreenshots = true;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "never"; # Previously appeared when pressing alt
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
            action = "useSystemDefault"; # Open VSCode app
            ask = false;
          };
          Handlers.schemes.element = {
            action = "useSystemDefault"; # Open Element app
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
            "extensions.autoDisableScopes" = 0; # Automatically enable extensions
            "extensions.update.enabled" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1; # Use new gtk file picker instead of legacy one
            "signon.management.page.breach-alerts.enabled" = false;
            "extensions.formautofill.creditCards.enabled" = false;
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
              amazondotcome-us.metaData.hidden = true;
              wikipedia.metaData.hidden = true;
            };
          };

          # Extensions. Install extensions from firefox-addons
          # which are more secure, verified, than previous xpi method.
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            proton-pass
            multi-account-containers
            ublock-origin
          ];
        };
      };

      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "application/pdf" = [ "firefox.desktop" ];
      };
    };
}
