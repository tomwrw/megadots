{ ... }:
{
  den.aspects.graphics.nixos =
    { ... }:
    {
      # GPU drivers / hardware acceleration, incl. 32-bit for Steam/Wine.
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    };
}
