_: {
  den.aspects.bluetooth.nixos =
    { pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        package = pkgs.bluez;
      };
    };

  den.aspects.bluetooth.persist.directories = [ "/var/lib/bluetooth" ];
}
