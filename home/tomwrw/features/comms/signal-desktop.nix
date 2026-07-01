{ pkgs, ... }:
{
  home.packages = [
    pkgs.signal-desktop
  ];

  # Session/device-link state; losing this forces re-linking as a new device.
  home.persistence."/persist".directories = [
    ".config/Signal"
  ];
}
