{ pkgs, ... }:
{
  home.packages = [
    pkgs.gemini-cli
  ];

  # Credentials/config.
  home.persistence."/persist".directories = [
    ".gemini"
  ];
}
