{
  config,
  lib,
  outputs,
  ...
}:
{
  imports = [
    ../features/cli
  ]
  # Include any custom Home Manager modules I have defined.
  ++ (builtins.attrValues outputs.homeModules);

  # This setting ensures that user-level systemd services are started correctly
  # when using Home Manager with NixOS. It's a required boilerplate for
  # proper integration.
  systemd.user.startServices = "sd-switch";
  # Enable these programs for this user on all hosts.
  programs = {
    home-manager.enable = true;
    git.enable = true;
  };
  # Set up my Home Manager instance.
  home = {
    # Configure user settings for home-manager.
    username = lib.mkDefault "tomwrw";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    sessionPath = [ "$HOME/.local/bin" ];
  };

  # Global persists for anything that could be global
  # or optional for Home Manager configs, like Steam.
  home.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "Development"
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Vaults"
      "Videos"
      ".local/bin"
      ".local/share/nix"
    ];
  };
}
