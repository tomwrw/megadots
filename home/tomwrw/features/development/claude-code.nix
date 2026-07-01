{ pkgs, ... }:
{
  home.packages = [
    pkgs.claude-code
    pkgs.claude-monitor
  ];

  # Credentials/config — getting this right matters since it holds auth
  # material.
  home.persistence."/persist".directories = [
    ".claude"
    ".config/claude"
  ];
}
