_: {
  # programs.mangohud rather than home.packages: the HM module is what Stylix's
  # mangohud target writes its settings through, so installing the bare package
  # would silently forfeit the theming.
  den.aspects.apps.gaming.mangohud.homeManager = _: {
    programs.mangohud.enable = true;
  };
}
