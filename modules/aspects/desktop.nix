{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.graphics
      den.aspects.audio
      den.aspects.bluetooth
      den.aspects.gnome
    ];

    nixos =
      { pkgs, ... }:
      {
        programs.ssh.enableAskPassword = true;
        programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
      };
  };
}
