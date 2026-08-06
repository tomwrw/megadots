_: {
  den.aspects.apps.gaming.emulation.homeManager =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.ryubing
        pkgs.cemu
      ];

      # Emulator config, firmware/keys and save data. Game dumps are a separate
      # user-managed concern - whatever holds those needs to sit under a
      # persisted directory (~/Documents and friends are covered in the tomwrw
      # aspect) or get an entry of its own.
      home.persistence."/persist".directories = [
        ".config/Ryujinx"
        ".local/share/Cemu"
      ];
    };
}
