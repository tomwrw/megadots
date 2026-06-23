_: {
  den.aspects.networking.nixos =
    { lib, ... }:
    {
      networking = {
        firewall.enable = lib.mkForce true;
        networkmanager.enable = true;
      };
    };
}
