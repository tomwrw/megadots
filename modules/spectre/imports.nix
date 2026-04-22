{config, ...}: {
  flake.modules.nixos.spectre.imports = with config.flake.modules.nixos; [
    gaming
    lanzaboote
  ];
}
