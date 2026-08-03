_: {
  den.aspects.hardware.bluetooth.nixos =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        package = pkgs.bluez;
      };
    };

  den.aspects.hardware.bluetooth.persist.directories = [ "/var/lib/bluetooth" ];
}
