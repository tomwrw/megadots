{ den, ... }:
{

  den.hosts.x86_64-linux.endgame = {
    settings = {
      system = {
        linux-kernel = {
          channel = "latest";
          optimization = "zen4";
        };
      };
    };
  };

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

        networking = {
          domain = "home.arpa";
          search = [ "home.arpa" ];
        };
      };
  };
}
