{ config, ... }:
{
  configurations.nixos.flatmate.module.imports = with config.flake.modules.nixos; [
    pc
    limine
  ];
}
