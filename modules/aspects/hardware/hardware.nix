_: {
  den.aspects.hardware = {
    nixos = _: {
      hardware.enableRedistributableFirmware = true;

      services.devmon.enable = true;
      services.fwupd.enable = true;
    };

    # State owned by the services enabled above. Emitted here rather than
    # centrally in the preservation aspect so that a host which does not
    # include this aspect does not persist directories nothing will create.
    persist.directories = [
      # Device history and the downloaded LVFS metadata. Without these,
      # fwupd re-fetches its metadata on every boot and forgets what it has
      # already flashed.
      "/var/lib/fwupd"
      "/var/cache/fwupd"
    ];
  };
}
