_: {
  den.aspects.networking.nixos =
    { lib, ... }:
    {
      networking = {
        # Deliberate policy lock: firewall must never be turned off by any
        # other aspect, even though `true` is already the NixOS default.
        firewall.enable = lib.mkForce true;
        networkmanager.enable = true;
      };
    };
}
