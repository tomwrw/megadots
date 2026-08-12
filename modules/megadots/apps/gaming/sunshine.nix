_: {
  megadots.apps.gaming.sunshine = {
    description = "The Sunshine remote-play host, LAN-scoped, with its Wayland portal permissions persisted.";

    nixos = _: {
      # Sunshine's virtual gamepad and keyboard need uinput, and nothing else
      # of mine does, so it lives here and not in hardware/hardware.nix where
      # it was loading the module and making a uinput group on hosts with no
      # use for either.
      hardware.uinput.enable = true;

      services.sunshine = {
        enable = true;
        autoStart = true;
        settings = {
          origin_web_ui_allowed = "lan";
          system_tray = "enabled";
        };
      };

    };

    # services.sunshine is a systemd user service, so its state is in my home
    # and not /var/lib. Delivered through provides.to-users because this aspect
    # is host scope, and the home-persist quirk is only read in a user scope.
    provides.to-users.home-persist.directories = [ ".config/sunshine" ];

    # LAN only, instead of openFirewall opening these everywhere. Same fixed
    # set of ports openFirewall = true would have opened.
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
