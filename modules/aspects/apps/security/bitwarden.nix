_: {
  den.aspects.apps.security.bitwarden.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-cli ];

      home.persistence."/persist".directories = [ ".config/Bitwarden CLI" ];
    };
}
