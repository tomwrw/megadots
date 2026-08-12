_: {
  megadots.apps.gaming.emulation = {
    description = "Switch and Wii U emulators, with their state directories persisted.";

    # Emulator config, firmware, keys and saves. Game dumps are my own
    # problem, so wherever I keep those needs to sit under something already
    # persisted, like ~/Documents in the tomwrw aspect, or get its own entry.
    home-persist.directories = [
      ".config/Ryujinx"
      ".local/share/Cemu"
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.ryubing
          pkgs.cemu
        ];
      };
  };
}
