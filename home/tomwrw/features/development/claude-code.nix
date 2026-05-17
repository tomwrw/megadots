{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    claude-monitor
  ];

  home.persistence."/persist" = {
    directories = [
      ".claude"
    ];
    files = [
      ".claude.json"
      ".claude.json.backup"
    ];
  };
}
