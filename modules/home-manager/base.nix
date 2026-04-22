{config, ...}: let
  owner = config.flake.meta.owner;
in {
  flake.modules.homeManager.base = {
    home.username = owner.username;
    home.homeDirectory = "/home/${owner.username}";
    programs.home-manager.enable = true;

    # Silences an evaluation warning — kept from the old user module.
    gtk.gtk4.theme = null;
  };
}
