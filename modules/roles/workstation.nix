{ den, megadots, ... }:
{
  # Everything that only makes sense in front of a screen. fonts and
  # networkmanager moved here out of roles.base: a headless host taking the
  # baseline was getting fourteen font packages and a Wi-Fi daemon it had no
  # way to drive.
  #
  # No desktop environment. This role used to include desktop.gnome, which was
  # fine while both machines ran the same one; endgame is on COSMIC now and
  # flatmate is still on GNOME, and a role that hardcodes one of them cannot
  # express that. The choice sits on the host instead, exactly like the
  # bootloader does - endgame takes core.boot.lanzaboote where flatmate takes
  # core.boot.systemd-boot. Two desktops installed at once is a working session
  # with the wrong greeter and two sets of portals, so this is deliberately not
  # something a host can forget to answer: the invariant in checks.nix fails a
  # workstation with no desktop rather than letting it boot to a black screen.
  den.aspects.roles.workstation.includes = [
    megadots.hardware.graphics
    megadots.hardware.audio
    megadots.hardware.bluetooth
    megadots.desktop.fonts
    megadots.desktop.networkmanager
  ];
}
