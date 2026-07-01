{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
  };

  environment.persistence."/persist".directories = [
    "/var/lib/bluetooth"
  ];
}
