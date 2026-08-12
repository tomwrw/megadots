_: {
  megadots.apps.security.bitwarden = {
    description = "The Bitwarden desktop client.";

    home-persist.directories = [ ".config/Bitwarden CLI" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.bitwarden-cli ];
      };
  };
}
