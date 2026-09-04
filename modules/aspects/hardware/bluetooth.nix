_: {
  # No package set, pkgs.bluez is already the module default.
  # Bluetooth, with its pairing database persisted.
  den.aspects.bluetooth.nixos = _: {
    hardware.bluetooth.enable = true;
  };

  den.aspects.bluetooth.persist.system.directories = [ "/var/lib/bluetooth" ];
}
