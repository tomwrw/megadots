_: {
  den.aspects.core.networking =
    { host, ... }:
    {
      nixos =
        {
          firewall,
          lib,
          ...
        }:
        {
          networking = {
            # mkForce so no other aspect can turn the firewall off, even
            # though true is already the default.
            firewall.enable = lib.mkForce true;
            networkmanager.enable = true;
            domain = "home.arpa";
            search = [ "home.arpa" ];

            # The only place that touches the firewall. Aspects say what ports
            # they need through the 'firewall' quirk and this puts them on the
            # host's LAN interface, so no aspect needs to know the interface
            # name and nothing can open a port globally by accident.
            #
            # lib.unique because an aspect included at both host and user
            # scope contributes its ports twice once pipe.expose has run.
            firewall.interfaces.${host.network.lanInterface} = {
              allowedTCPPorts = lib.unique (lib.concatMap (f: f.tcp or [ ]) firewall);
              allowedUDPPorts = lib.unique (lib.concatMap (f: f.udp or [ ]) firewall);
            };
          };

          assertions = [
            {
              assertion = host.network.lanInterface != "" && host.network.lanInterface != "REPLACE_ME";
              message = "host ${host.name}: den.hosts.<system>.${host.name}.network.lanInterface must name a real interface (see 'ip -br link'); every LAN-scoped firewall rule hangs off it.";
            }
          ];
        };

      # NetworkManager's state, kept by the aspect that turns it on. Its
      # secret_key derives the per-SSID MAC and the DHCP DUID, so losing it
      # means a new identity every boot, fresh leases and broken reservations.
      persist.directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
      ];
    };
}
