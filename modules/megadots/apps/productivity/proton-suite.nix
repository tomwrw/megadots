_: {
  megadots.apps.productivity.proton-suite = {
    description = "The Proton Pass, VPN and Mail desktop clients.";

    # UNVERIFIED: session and login state for both apps. Check 'ls ~/.config'
    # after first run.
    home-persist.directories = [
      ".config/Proton"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.proton-pass
          pkgs.proton-vpn
        ];
      };
  };
}
