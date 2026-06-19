{ den, ... }:
{
  den.aspects.endgame = {
    includes = [
      den.aspects.base
      den.aspects.desktop
      den.aspects.secure-boot
      den.aspects.gaming
      den.aspects.virtualisation
      den.aspects.preservation
    ];

    nixos =
      { ... }:
      {
        imports = [
          ./_disko.nix
          ./_hardware.nix
        ];
        # hostName comes from the hostname battery (host entity name);
        # stateVersion from den.default.
        networking = {
          domain = "home.arpa";
          search = [ "home.arpa" ];
        };
      };
  };
}
