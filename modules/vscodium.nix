{
  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        package = pkgs.vscodium;
        profiles = {
          default = {
            extensions = with pkgs.vscode-extensions; [
              jnoortheen.nix-ide
              yzhang.markdown-all-in-one
            ];
            userSettings = {
              "git.confirmSync" = false;
              "git.enableSmartCommit" = true;
              "git.autofetch" = true;
              "explorer.confirmDragAndDrop" = false;
              "explorer.confirmDelete" = false;
              "claudeCode.preferredLocation" = "panel";
              "claudeCode.claudeProcessWrapper" = "/etc/profiles/per-user/tomwrw/bin/claude";
            };
          };
        };
      };
    };
}