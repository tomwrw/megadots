{ den, ... }:
{
  den.aspects.roles.workstation.includes = [
    den.aspects.hardware.graphics
    den.aspects.hardware.audio
    den.aspects.hardware.bluetooth
    den.aspects.desktop.gnome
  ];
}
