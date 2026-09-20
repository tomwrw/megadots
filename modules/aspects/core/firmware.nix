_: {
  # Firmware and fwupd - the parts every physical machine wants.
  #
  # No services.devmon. That is udevil's automounter for a machine without a
  # desktop doing it; both hosts run GNOME, where gvfs and udisks2 already
  # do, so it was a user daemon sitting in every session mounting nothing.
  den.aspects.firmware = {
    nixos = _: {
      hardware.enableRedistributableFirmware = true;

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
