{config, ...}: {
  flake.modules.nixos.flatmate.imports = with config.flake.modules.nixos; [
    pc
    systemd-boot
  ];
}
