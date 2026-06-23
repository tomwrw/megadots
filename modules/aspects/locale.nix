_: {
  den.aspects.locale.nixos =
    { lib, ... }:
    {
      # Set the time zone.
      time.timeZone = lib.mkDefault "Europe/London";

      # Select internationalisation properties.
      i18n.defaultLocale = "en_GB.UTF-8";

      # Configure additional locales.
      i18n.extraLocaleSettings = {
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

      # Update the xkb layout to British.
      services.xserver.xkb.layout = "gb";

      # Configure console keymap.
      console.keyMap = lib.mkDefault "uk";
    };
}
