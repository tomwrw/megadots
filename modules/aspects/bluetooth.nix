{ ... }:
{
  den.aspects.bluetooth.nixos =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        package = pkgs.bluez;
      };
    };

  # Persist pairing/adapter state across reboots on impermanent hosts.
  den.aspects.bluetooth.persist.directories = [ "/var/lib/bluetooth" ];
}
