{ lib, ... }:
{
  services = {
    # Disabling speechd, the speech dispatcher daemon, as it's not
    # needed for most desktop use cases and can consume resources.
    speechd.enable = lib.mkForce false;
    # Wrapper service for udisks.
    devmon.enable = true;
    # Firmware update service.
    services.fwupd.enable = true;
    # fail2ban for protection against credential stuffing.
    services.fail2ban.enable = true;
  };
}
