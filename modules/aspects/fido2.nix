_: {
  den.aspects.fido2.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.libfido2
        pkgs.fido2-manage
        pkgs.age-plugin-fido2-hmac
      ];
    };
}
