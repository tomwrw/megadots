{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
  };
  # This app/config requires the following persisted directories
  # and folders. Be This will only apply if impermanence is
  # enabled, and as soon as a user and host become out of
  # scope for this module, the items here will no longer
  # be persisted (they'll still exist in /persist thought).
  environment.persistence."/persist" = {
    directories = [
      "/var/lib/bluetooth"
    ];
  };
}
