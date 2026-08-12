_: {
  megadots.apps.gaming.sunshine = {
    description = "The Sunshine remote-play host. LAN-scoped ports, its own config left writable so the web UI works.";

    nixos = _: {
      # Sunshine's virtual gamepad and keyboard need uinput, and nothing else
      # of mine does, so it lives here and not in hardware/hardware.nix where
      # it was loading the module and making a uinput group on hosts with no
      # use for either.
      hardware.uinput.enable = true;

      # No 'settings' block, and that is the whole point. The nixpkgs module
      # only passes Sunshine a --config path when applications are declared or
      # more than the default port is set:
      #
      #   # only add configFile if an application or a setting other than the
      #   # default port is set to allow configuration from web UI
      #   ExecStart = ... ++ optionals (
      #     cfg.applications.apps != [ ]
      #     || (builtins.length (builtins.attrNames cfg.settings) > 1
      #         || cfg.settings.port != defaultPort)
      #   ) [ "${configFile}" ];
      #
      # Two settings here - origin_web_ui_allowed and system_tray - were enough
      # to trip that, so Sunshine was reading a /nix/store config it could never
      # write back to, and every change made in the web UI was discarded. That
      # looked like an impermanence problem and wasn't: .config/sunshine below
      # has been persisted all along, and Sunshine simply never wrote to it.
      #
      # Left alone, Sunshine owns ~/.config/sunshine/sunshine.conf and apps.json
      # and the web UI works. Pairing a client and adding games are things done
      # once, on the machine, against a running service - the kind of state this
      # config persists rather than declares.
      services.sunshine = {
        enable = true;
        autoStart = true;
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
