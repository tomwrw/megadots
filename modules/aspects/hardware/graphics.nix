_: {
  # Graphics drivers, including the 32-bit stack games need.
  den.aspects.graphics.nixos = _: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
