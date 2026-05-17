_: {
  programs.vesktop = {
    enable = true;
  };

  home.persistence."/persist" = {
    directories = [
      ".config/vesktop"
    ];
  };
}
