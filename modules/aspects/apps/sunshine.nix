_: {
  den.aspects.apps.gaming.sunshine =
    { host, ... }:
    {
      nixos = _: {
        # Sunshine's virtual gamepad/keyboard needs uinput. This is its only
        # consumer in the fleet, so it lives here rather than in
        # hardware/hardware.nix, where it was loading the module and creating a
        # uinput group on hosts that have no use for either.
        hardware.uinput.enable = true;

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
