{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez;
  };

  preservation = {
    preserveAt."/persist" = {
      directories = [
        "/var/lib/bluetooth"
      ];
    };
  };
}
