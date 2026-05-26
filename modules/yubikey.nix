{
  flake.modules.nixos.pc =
    { pkgs, ... }:
    {

      environment.systemPackages = [
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
        pkgs.yubikey-touch-detector
        pkgs.yubioath-flutter
      ];

      services.udev.packages = [
        pkgs.yubikey-personalization
      ];

      services.pcscd.enable = true;

      programs.yubikey-touch-detector.enable = true;

      programs.gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-gnome3;
      };
    };
}
