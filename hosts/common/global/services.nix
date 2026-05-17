{ lib, ... }:
{
  services = {
    # Disabling speechd, the speech dispatcher daemon, as it's not
    # needed for most desktop use cases and can consume resources.
    speechd.enable = lib.mkForce false;
    # Wrapper service for udisks.
    devmon.enable = true;
  };
}
