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
            # Deliberate choice here - firewall must never be turned off by any
            # other aspect, even though 'true' is already the NixOS default.
            firewall.enable = lib.mkForce true;
            networkmanager.enable = true;
            domain = "home.arpa";
            search = [ "home.arpa" ];

            # The fleet's only firewall consumer. Aspects declare what they
            # need via the 'firewall' quirk and this aggregates it onto the
            # host's LAN interface, so no aspect has to know the interface
            # name and nothing can accidentally open a port globally.
            #
            # lib.unique because an aspect included at both host and user
            # scope contributes its entry twice once pipe.expose has run.
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

      # NetworkManager's own state, owned by the aspect that enables it.
      # secret_key is what derives stable per-SSID MAC addresses and the DHCP
      # DUID, so discarding it means a new hardware identity on every boot -
      # new DHCP leases, and any address reservations stop matching.
      persist.directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
      ];
    };
}
