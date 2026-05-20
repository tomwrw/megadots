{ config, ... }:
{
  programs = {
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      enableCompletion = true;
      shellAliases = {
        nix-clean = "nix-collect-garbage -d --delete-old && sudo nix-collect-garbage -d --delete-old";
        hstat = "curl -o /dev/null --silent --head --write-out '%{http_code}\n' $1";
        l = "ls -l";
        ls = "ls -h --group-directories-first --color=auto";
        la = "ls -lAh --group-directories-first --color=auto";
        psf = "ps -aux | grep";
        lsf = "ls | grep";
        nsp = "nix search nixpkgs";
      };
      history = {
        # Fix https://github.com/nix-community/impermanence/issues/233
        # Persisting the history file in default location
        # was failing so using this workaround.
        path = "$HOME/.local/share/zsh/.zsh_history";
        size = 8000;
      };
    };
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      settings = {
        add_newline = false;
        directory = {
          truncation_length = 2;
          format = "[$path]($style)[$read_only]($read_only_style) ";
        };
        # Git
        git_commit = {
          disabled = false;
        };
        hostname = {
          ssh_only = false;
          format = "[$hostname]($style) ";
        };
        username.show_always = true;
      };
    };
  };

  home = {
    sessionVariables = {
      SPACESHIP_EXIT_CODE_SHOW = "true";
    };
  };
}
