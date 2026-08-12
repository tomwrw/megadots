_: {
  # No package set, pkgs.bluez is already the module default.
  megadots.hardware.bluetooth.description = "Bluetooth, with its pairing database persisted.";

  megadots.hardware.bluetooth.nixos = _: {
    hardware.bluetooth.enable = true;
  };

  megadots.hardware.bluetooth.persist.directories = [ "/var/lib/bluetooth" ];
}
