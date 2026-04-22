{config, ...}: {
  flake.modules.nixos.endgame.imports = with config.flake.modules.nixos; [
    gaming
    lanzaboote
  ];
}
