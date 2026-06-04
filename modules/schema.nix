{ lib, ... }:
{
  den.schema.host =
    { lib, ... }:
    {
      # Per-host Syncthing identity. Each host declares its own device ID in the
      # roster (modules/hosts.nix); the Syncthing HM aspect reads den.hosts to
      # build the mesh, so there is no central device map.
      options.syncthing = {
        enable = lib.mkEnableOption "participation in the Syncthing mesh" // {
          default = true;
        };
        id = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "This host's Syncthing device ID (must match its provisioned cert).";
        };
      };
    };

  den.schema.user = {
    config.classes = lib.mkDefault [ "homeManager" ];
  };
}
