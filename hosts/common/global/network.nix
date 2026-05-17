{ lib, ... }:
{
  # Enable the firewall and network manager. Firewall
  # rules are added in any module that requires
  # a specific exception.
  networking = {
    firewall = {
      enable = lib.mkForce true;
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        22000
        21027
      ];
    };
    networkmanager = {
      enable = true;
    };
  };
}
