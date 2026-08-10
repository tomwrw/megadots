_: {
  den.aspects.apps.productivity.proton-suite.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.proton-pass
        pkgs.proton-vpn
      ];

      # UNVERIFIED: session and login state for both apps. Check 'ls ~/.config'
      # after first run.
      home.persistence."/persist".directories = [
        ".config/Proton"
      ];
    };
}
