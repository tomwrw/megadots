{ den, ... }:
{
  # Bundle of the desktop hardware/services every graphical host wants, keeping
  # per-host include lists short. A host wanting only a subset can include the
  # individual aspects directly instead.
  den.aspects.desktop.includes = [
    den.aspects.graphics
    den.aspects.audio
    den.aspects.bluetooth
    den.aspects.gnome
  ];
}
