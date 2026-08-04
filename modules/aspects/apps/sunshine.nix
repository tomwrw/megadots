_: {
  den.aspects.apps.gaming.sunshine =
    { host, ... }:
    {
      nixos = _: {
        services.sunshine = {
          enable = true;
          autoStart = true;
          settings = {
            origin_web_ui_allowed = "lan";
            system_tray = "disabled";
          };
        };

        # LAN-scoped instead of openFirewall's global allow. Ports are
        # sunshine's own fixed set (unrelated to host identity), matching
        # what openFirewall = true used to open.
        networking.firewall.interfaces.${host.network.lanInterface} = {
          allowedTCPPorts = [
            47984
            47989
            47990
            48010
          ];
          allowedUDPPorts = [
            47998
            47999
            48000
            48002
            48010
          ];
        };
      };
    };
}
