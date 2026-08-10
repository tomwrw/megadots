_: {
  den.aspects.apps.storage.filen-desktop.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.filen-desktop ];

      home.persistence."/persist".directories = [ ".config/@filen" ];
    };
}
