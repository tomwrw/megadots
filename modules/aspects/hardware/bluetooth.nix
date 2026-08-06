_: {
  # No package set, pkgs.bluez is already the module default.
  den.aspects.hardware.bluetooth.nixos = _: {
    hardware.bluetooth.enable = true;
  };

  den.aspects.hardware.bluetooth.persist.directories = [ "/var/lib/bluetooth" ];
}
