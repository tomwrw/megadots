# This file (and the global directory) holds config that i use on all hosts
{
  hardware = {
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    uinput.enable = true;
  };

  # Allow users to mount removable drives.
  services.udisks2.enable = true;
}
