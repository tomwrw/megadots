{
  # Enable rtkit and polkit for all hosts.
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    # Passwordless sudo for wheel members. SSH access is already
    # restricted to pubkey auth, so the practical guard against
    # privilege escalation is "do you have my SSH key", not
    # "do you also know a separate sudo password."
    sudo.wheelNeedsPassword = false;
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
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];
  };
}
