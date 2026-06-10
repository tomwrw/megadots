_: {
  den.aspects.hardware.nixos =
    { lib, ... }:
    {
      # Core hardware settings. Redistributable firmware covers everything
      # these hosts need (linux-firmware: amdgpu, iwlwifi, …) without the
      # unfree blobs that enableAllFirmware would drag in.
      hardware = {
        enableRedistributableFirmware = true;
        uinput.enable = true;
      };

      # Wrapper service for udisks. Lets non-root users mount removable
      # media without polkit prompts.
      services.devmon.enable = true;

      # Firmware update service (fwupd / LVFS).
      services.fwupd.enable = true;

      # Disabling speechd, the speech dispatcher daemon, as it's not
      # needed for most desktop use cases and can consume resources.
      services.speechd.enable = lib.mkForce false;
    };
}
