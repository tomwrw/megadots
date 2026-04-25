{
  configurations.nixos.endgame.module = {
    boot.loader = {
      timeout = 15;
      systemd-boot = {
        configurationLimit = 10;
        # To find the Windows boot drive, set edk2-uefi-shell.enable = true,
        # boot into it, run `map -c` for drive aliases, then `FSn:` and `ls EFI`
        # to identify which alias holds the Windows EFI partition.
        windows."windows" = {
          title = "Windows";
          efiDeviceHandle = "FS2";
          sortKey = "y_windows";
        };
        edk2-uefi-shell = {
          enable = false;
          sortKey = "z_edk2";
        };
      };
    };
  };
}
