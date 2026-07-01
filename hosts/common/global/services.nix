{ lib, ... }:
{
  services = {
    # Disabling speechd, the speech dispatcher daemon. GNOME's orca
    # accessibility module enables it, so mkForce is required to win.
    speechd.enable = lib.mkForce false;
    # Wrapper service for udisks.
    devmon.enable = true;
    # Firmware update service.
    fwupd.enable = true;
    # fail2ban for protection against credential stuffing.
    fail2ban.enable = true;
  };
}
