_: {
  # programs.mangohud rather than home.packages: the HM module is what Stylix's
  # mangohud target writes its settings through, so installing the bare package
  # would lose the theming.
  # The MangoHud performance overlay.
  den.aspects.mangohud.homeManager = _: {
    programs.mangohud.enable = true;

    # Nothing to persist: settings are written on activation and mangohud keeps
    # no runtime state of its own.
  };
}
