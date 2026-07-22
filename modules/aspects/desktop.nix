{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.graphics
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.gnome
    ];
  };
}
