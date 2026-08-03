_: {
  den.aspects.apps.gaming.sunshine.nixos = _: {
    services.sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = true;
      settings = {
        origin_web_ui_allowed = "lan";
        system_tray = "disabled";
      };
    };
  };
}
