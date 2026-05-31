{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  services.udev.packages = [ pkgs.sunshine ];

  # CAP_SYS_ADMIN is a very powerful capability that can
  # be used to escape containers and perform many privileged
  # operations. Currently this is needed for Wayland capture.
  # I need to keep an eye on the below pull request, as it
  # looks like lizardbyte are in the process of releasing
  # an update that performs capture through XDG Portal
  # like how OBS etc. do it. This means capSysAdmin can be
  # removed when the PR is merged.
  # https://github.com/LizardByte/Sunshine/pull/4417
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  hardware.steam-hardware.enable = true;

  environment.systemPackages = [
    pkgs.game-devices-udev-rules
  ];
}
