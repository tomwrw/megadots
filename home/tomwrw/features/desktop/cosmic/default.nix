_: {
  # This app requires the following persisted directories
  # and folders. Be This will only apply if impermanence is
  # enabled, and as soon as a user and host become out of
  # scope for this module, the items here will no longer
  # be persisted (they'll still exist in /persist thought).
  home.persistence."/persist" = {
    directories = [
      # Persisted directories go here (if needed).
      ".config/cosmic"
    ];
    files = [
      # Persisted files go here (if needed).
    ];
  };
}
