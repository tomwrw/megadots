{ lib, ... }:
{
  den.schema.host =
    {
      host,
      lib,
      ...
    }:
    { };

  den.schema.user = {
    config.classes = lib.mkDefault [ "homeManager" ];
  };
}
