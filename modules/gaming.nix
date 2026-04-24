{ config, ... }:
{
  flake.modules.nixos.gaming.imports = with config.flake.modules.nixos; [ pc ];
}
