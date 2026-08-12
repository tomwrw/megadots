_: {
  megadots.apps.monitoring.btop.description = "The btop resource monitor.";

  megadots.apps.monitoring.btop.homeManager = _: {
    programs.btop.enable = true;
  };
}
