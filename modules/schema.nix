{ lib, ... }:
{
  den.schema.host =
    { lib, ... }:
    {
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
