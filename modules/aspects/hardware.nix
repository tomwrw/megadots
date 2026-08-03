_: {
  den.aspects.hardware.nixos = _: {
    hardware = {
      enableRedistributableFirmware = true;
      uinput.enable = true;
    };

    services.devmon.enable = true;
    services.fwupd.enable = true;
  };
}
