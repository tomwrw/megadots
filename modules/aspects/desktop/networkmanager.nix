_: {
  # Split out of the networking aspect, which every host takes through base.
  # NetworkManager is a desktop concern - it exists so GNOME's applet can pick
  # a Wi-Fi network - and a headless machine taking the baseline was getting a
  # daemon it had no way to drive. core.networking keeps the parts that really
  # are universal: the firewall aggregation, the domain and the search list.
  # NetworkManager and the two directories that hold saved connections.
  den.aspects.networkmanager = {
    nixos = _: {
      networking.networkmanager.enable = true;
    };

    # NetworkManager's state, kept by the aspect that turns it on. Its
    # secret_key derives the per-SSID MAC and the DHCP DUID, so losing it means
    # a new identity every boot, fresh leases and broken reservations.
    persist.system.directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
    ];
  };
}
