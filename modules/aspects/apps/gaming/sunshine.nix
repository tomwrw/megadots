_: {
  den.aspects.apps.gaming.sunshine = {
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

    };

    # services.sunshine is a systemd USER service, so its state lives in the
    # home, not /var/lib. Delivered through provides.to-users because this
    # aspect is host-scope and den drops a bare homeManager key there.
    provides.to-users.homeManager = _: {
      # UNVERIFIED: holds the paired-client certificates. Losing it does not
      # break anything visibly - Sunshine just comes up with no clients paired
      # and every device has to re-enter its PIN.
      home.persistence."/persist".directories = [ ".config/sunshine" ];
    };

    # LAN-scoped instead of openFirewall's global allow. Ports are
    # sunshine's own fixed set, matching what openFirewall = true opens.
    firewall = {
      tcp = [
        47984
        47989
        47990
        48010
      ];
      udp = [
        47998
        47999
        48000
        48002
        48010
      ];
    };
  };
}
