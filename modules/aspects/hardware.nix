_: {
  den.aspects.hardware.nixos =
    { lib, ... }:
    {
      hardware = {
        enableRedistributableFirmware = true;
        uinput.enable = true;
      };

      services.devmon.enable = true;
      services.fwupd.enable = true;
      services.speechd.enable = lib.mkForce false;
    };
}
