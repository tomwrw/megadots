_: {
  # Timezone and locale, all overridable, with no keyboard layout - that belongs to the desktop.
  den.aspects.locale.nixos =
    { lib, ... }:
    {
      # Set the time zone.
      time.timeZone = lib.mkDefault "Europe/London";

      # mkDefault throughout, like timeZone and console.keyMap either side of
      # it. These were plain assignments, which meant a host wanting a
      # different locale had to reach for mkForce to override the baseline it
      # had opted into - the two neighbours already got this right.
      i18n.defaultLocale = lib.mkDefault "en_GB.UTF-8";

      # Configure additional locales.
      i18n.extraLocaleSettings = lib.mkDefault {
        LC_ADDRESS = "en_GB.UTF-8";
        LC_IDENTIFICATION = "en_GB.UTF-8";
        LC_MEASUREMENT = "en_GB.UTF-8";
        LC_MONETARY = "en_GB.UTF-8";
        LC_NAME = "en_GB.UTF-8";
        LC_NUMERIC = "en_GB.UTF-8";
        LC_PAPER = "en_GB.UTF-8";
        LC_TELEPHONE = "en_GB.UTF-8";
        LC_TIME = "en_GB.UTF-8";
      };

      # No services.xserver.xkb here. The keyboard layout is a desktop concern
      # and lives in desktop/gnome.nix; this aspect is in base, so a
      # headless host was getting X keyboard config it had no use for.

      # Configure console keymap.
      console.keyMap = lib.mkDefault "uk";
    };
}
