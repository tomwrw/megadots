{ ... }:
{
  den.aspects.networking.nixos =
    { lib, ... }:
    {
      # Enable the firewall and network manager. Firewall
      # rules are added in any module that requires
      # a specific exception.
      networking = {
        # Local DNS search domain for short hostnames on the home LAN.
        search = [ "home.arpa" ];
        firewall.enable = lib.mkForce true;
        networkmanager.enable = true;
      };
    };
}
