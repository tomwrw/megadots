_: {
  den.aspects.apps.security.bitwarden.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-cli ];

      # UNVERIFIED: the CLI's session/config store, which holds the vault URL
      # and the encrypted session key. Confirm with `ls ~/.config` after a
      # first `bw login`; without it every shell starts logged out.
      home.persistence."/persist".directories = [ ".config/Bitwarden CLI" ];
    };
}
