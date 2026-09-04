{ den, ... }:
{
  # Everything that only makes sense in front of a screen. fonts and
  # networkmanager sit here rather than in base, so a headless host is not
  # handed fourteen font packages and a Wi-Fi daemon it cannot drive.
  #
  # No desktop environment, deliberately. The choice sits on the host next to
  # its bootloader, which is what let endgame run COSMIC for a while and go back
  # to GNOME without this file changing. Two desktops at once is a working
  # session with the wrong greeter and two sets of portals; none at all builds
  # perfectly and boots to a black screen.
  den.aspects.workstation.includes = [
    # Hardware the session needs
    den.aspects.audio
    den.aspects.bluetooth
    den.aspects.graphics

    # The session itself
    den.aspects.fonts
    den.aspects.networkmanager
  ];
}
