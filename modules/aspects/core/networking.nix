_: {
  den.aspects.core.networking =
    { host, ... }:
    {
      nixos =
        { lib, ... }:
        {
          networking = {
            # Deliberate choice here - firewall must never be turned off by any
            # other aspect, even though 'true' is already the NixOS default.
            firewall.enable = lib.mkForce true;
            networkmanager.enable = true;
            domain = "home.arpa";
            search = [ "home.arpa" ];
            # mDNS (avahi) - not explicitly enabled by anything in my config,
            # it's auto-enabled by the GNOME desktop module. LAN-scoped here
            # rather than left on the global allow-list, alongside ssh/
            # syncthing/sunshine's own interface-scoped ports.
            firewall.interfaces.${host.network.lanInterface}.allowedUDPPorts = [ 5353 ];
          };

          # avahi.openFirewall defaults to true upstream (same as
          # openssh) - must be explicit false or its own default reopens
          # 5353 globally alongside the interface-scoped rule above.
          services.avahi.openFirewall = false;
        };
    };
}
