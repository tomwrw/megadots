{ pkgs, ... }:
{
  # Enable zsh, the standard shell I use
  # on all my hosts.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };
  # Set the user default shell to zsh.
  users.defaultUserShell = pkgs.zsh;
  # Include the zsh shell package.
  environment.shells = [ pkgs.zsh ];
}
