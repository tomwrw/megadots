{ den, megadots, ... }:
{
  # Everything that only makes sense in front of a screen. fonts and
  # networkmanager moved here out of roles.base: a headless host taking the
  # baseline was getting fourteen font packages and a Wi-Fi daemon it had no
  # way to drive.
  den.aspects.roles.workstation.includes = [
    megadots.hardware.graphics
    megadots.hardware.audio
    megadots.hardware.bluetooth
    megadots.desktop.gnome
    megadots.desktop.fonts
    megadots.desktop.networkmanager
  ];
}
