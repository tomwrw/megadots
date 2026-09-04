_: {
  # The Proton Pass, VPN and Mail desktop clients.
  # UNVERIFIED: session and login state for both apps. Check 'ls ~/.config'
  den.aspects.proton-suite = {
    # after first run.
    persist.home.directories = [
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
