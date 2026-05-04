{
  configurations.nixos.endgame.module = {
    boot.loader = {
      timeout = 15;
      # Chainload Windows from its EFI System Partition on nvme0n1p3.
      # The PARTUUID is the GPT partition entry UUID — find via
      # `lsblk -o NAME,PARTLABEL,PARTUUID` if the disk is ever replaced.
      limine.extraEntries = ''
        /Windows
            protocol: efi_chainload
            image_path: uuid(c67f6b36-94ea-46a9-8be3-6a4af0fe4a4e):/EFI/Microsoft/Boot/bootmgfw.efi
      '';
    };
  };
}
