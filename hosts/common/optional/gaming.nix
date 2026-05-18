{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  services.udev.packages = [ pkgs.sunshine ];
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48000;
      }
      {
        from = 8000;
        to = 8010;
      }
    ];
  };
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
    capSysAdmin = false; # only needed for Wayland -- omit this when using with Xorg
    openFirewall = true;
  };

  hardware.steam-hardware.enable = true;

  environment.systemPackages = with pkgs; [
    game-devices-udev-rules
  ];
}
