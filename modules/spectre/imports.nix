{ config, ... }:
{
  configurations.nixos.spectre.module.imports = with config.flake.modules.nixos; [
    gaming
    secure-boot
  ];
}
