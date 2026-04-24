{
  flake.modules.homeManager.pc = {
    programs.ghostty = {
      enable = true;
      enableFishIntegration = true;
      installBatSyntax = true;
    };

    dconf.settings = {
      "org/gnome/desktop/applications/terminal" = {
        exec = "ghostty";
        exec-arg = "";
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        command = "ghostty";
        binding = "<Super>Return";
      };
    };
  };
}
