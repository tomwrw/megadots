_: {
  den.aspects.apps.gaming.emulation.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ryubing
        pkgs.cemu
      ];

      # Emulator config, firmware, keys and saves. Game dumps are my own
      # problem, so wherever I keep those needs to sit under something already
      # persisted, like ~/Documents in the tomwrw aspect, or get its own entry.
      home.persistence."/persist".directories = [
        ".config/Ryujinx"
        ".local/share/Cemu"
      ];
    };
}
