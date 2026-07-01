{
  # Enable the firewall and network manager. Firewall
  # rules are added in any module that requires
  # a specific exception.
  networking = {
    search = [ "home.arpa" ];
    firewall = {
      enable = true;
    };
    networkmanager = {
      enable = true;
    };
  };
}
