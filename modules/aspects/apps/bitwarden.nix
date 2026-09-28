_: {
  # The Bitwarden desktop client and CLI. The comment here used to say "desktop
  # client" while only the CLI was installed.
  #
  # The browser extension is not here. It comes from firefox-addons in
  # apps/firefox.nix, because an extension is part of a browser profile rather
  # than a package in the home - and putting it here would mean this aspect only
  # worked for someone who also took the firefox aspect.
  den.aspects.bitwarden = {
    persist.home.directories = [
      # The desktop client: the local account list, the encrypted vault cache
      # and the biometric/session unlock state. Electron names its directory
      # after the app, so this is "Bitwarden" and not a reverse-DNS id.
      ".config/Bitwarden"
      ".config/Bitwarden CLI"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          # bitwarden-desktop, not bitwarden: the short name became a throw
          # alias in nixpkgs on 2025-10-27 and now fails at eval.
          pkgs.bitwarden-desktop
          pkgs.bitwarden-cli
        ];
      };
  };
}
