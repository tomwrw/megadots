{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.libfido2
    pkgs.fido2-manage
    pkgs.pam_u2f
    pkgs.age-plugin-fido2-hmac
  ];

  sops.secrets."u2f/mappings" = { };

  security.pam.u2f.settings = {
    cue = true;
    pinverification = 1;
    origin = "pam://megadots";
    appid = "pam://megadots";
    authfile = config.sops.secrets."u2f/mappings".path;
  };
  security.pam.services.sudo.u2f.enable = true;

  boot.initrd.luks.devices.crypted.crypttabExtraOpts = [ "fido2-device=auto" ];
}
