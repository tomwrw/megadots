{ config, ... }:
{
  configurations.nixos.endgame.module.imports = with config.flake.modules.nixos; [
    gaming
    lanzaboote
  ];
}
