_: {
  # Firmware, device automounting and fwupd - the parts every physical machine wants.
  den.aspects.firmware = {
    nixos = _: {
      hardware.enableRedistributableFirmware = true;

      services.devmon.enable = true;
      services.fwupd.enable = true;
    };

    # State belonging to the services above. Kept here and not in the
    # impermanence aspect so a host that skips this one doesn't persist
    # directories nothing is going to create.
    persist.system.directories = [
      # Device history and the downloaded LVFS metadata. Without these fwupd
      # re-fetches its metadata every boot and forgets what it has flashed.
      "/var/lib/fwupd"
      "/var/cache/fwupd"
    ];
  };
}
