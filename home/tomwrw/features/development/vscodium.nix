{ pkgs, ... }:
{
  programs.vscodium = {
    enable = true;
    package = pkgs.vscodium;
    profiles = {
      default = {
        extensions = with pkgs.vscode-extensions; [
          # anthropic.claude-code
          jnoortheen.nix-ide
          yzhang.markdown-all-in-one
        ];
        userSettings = {
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.autofetch" = true;
          "git.allowForcePush" = true;
          "explorer.confirmDragAndDrop" = false;
          "explorer.confirmDelete" = false;
          "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
              };
            };
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
        };
      };
    };
  };

  home.persistence."/persist" = {
    directories = [
      ".config/Code"
      ".config/VSCodium"
      ".vscode"
      ".vscode-oss"
    ];
  };
}
