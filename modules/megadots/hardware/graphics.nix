_: {
  megadots.hardware.graphics.description = "Graphics drivers, including the 32-bit stack games need.";

  megadots.hardware.graphics.nixos = _: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
