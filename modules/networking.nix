{
  flake.modules.nixos.base.networking = {
    firewall.enable = true;
    networkmanager.enable = true;
  };
}
