_: {
  den.aspects.apps.productivity.proton-suite.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.proton-pass
        pkgs.proton-vpn
      ];

      # UNVERIFIED: session/login state for both apps. Confirm with
      # `ls ~/.config` after first run.
      home.persistence."/persist".directories = [
        ".config/Proton Pass"
        ".config/ProtonVPN"
      ];
    };
}
