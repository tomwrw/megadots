_: {
  den.aspects.hardware.nixos = _: {
    hardware.enableRedistributableFirmware = true;

    services.devmon.enable = true;
    services.fwupd.enable = true;
  };
}
