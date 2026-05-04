{
  flake.modules.nixos.limine = {
    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        maxGenerations = 10;
      };
    };
  };
}
