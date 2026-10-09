_: {
  # The Filen encrypted storage client.
  den.aspects.filen-desktop = {
    persist.home.directories = [ ".config/@filen" ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          # The bundled canvas 3.1.0 native module uses uint8_t without
          # including <cstdint>, which GCC 16 no longer pulls in transitively,
          # so the npm rebuild fails. node-gyp's makefiles read CXXFLAGS, so
          # this force-includes the header for C++ only. Drop it once nixpkgs
          # builds filen-desktop again.
          (pkgs.filen-desktop.overrideAttrs (old: {
            env = (old.env or { }) // {
              CXXFLAGS = "-include cstdint";
            };
          }))
        ];
      };
  };
}
