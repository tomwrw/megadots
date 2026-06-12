_: {
  den.aspects.fido2.nixos =
    { config, pkgs, ... }:
    {
      # FIDO2 tooling: fido2-token CLI (libfido2), Token2's fido2-manage,
      # pamu2fcfg (pam_u2f) and the age plugin used for sops recovery
      # recipients.
      environment.systemPackages = [
        pkgs.libfido2
        pkgs.fido2-manage
        pkgs.pam_u2f
        pkgs.age-plugin-fido2-hmac
      ];

      # uaccess rules for FIDO hidraw devices — belt-and-braces alongside
      # systemd's built-in fido-id rules.
      services.udev.packages = [ pkgs.libfido2 ];

      # sudo accepts a registered key (cued touch) as an alternative to the
      # password; login/GDM are deliberately left untouched. The credential
      # mapping ships as a sops secret so the public repo doesn't expose
      # credential IDs. Fixed origin/appid so one mapping works fleet-wide
      # (the default origin is per-hostname).
      sops.secrets."u2f/mappings" = { };
      security.pam.u2f.settings = {
        cue = true;
        # The PIN+ firmware sets alwaysUv: the token refuses assertions
        # without user verification, so sudo is PIN + touch.
        pinverification = 1;
        origin = "pam://megadots";
        appid = "pam://megadots";
        authfile = config.sops.secrets."u2f/mappings".path;
      };
      security.pam.services.sudo.u2f.enable = true;

      # Unlock the LUKS volume with an enrolled key at boot (see
      # `just enroll-fido2`); the passphrase slot remains as fallback.
      boot.initrd.luks.devices.crypted.crypttabExtraOpts = [ "fido2-device=auto" ];
    };
}
