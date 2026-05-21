{
  # Enable rtkit and polkit for all hosts.
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };
  # Enable PAM security settings for all hosts.
  security.pam = {
    # The default open file limit is often too low for modern applications,
    # especially for development, gaming, and other intensive tasks. Increasing
    # this limit prevents "too many open files" errors.
    loginLimits = [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "65536";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "131072";
      }
    ];
  };
}
