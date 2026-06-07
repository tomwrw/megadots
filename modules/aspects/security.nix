{ ... }:
{
  den.aspects.security.nixos =
    { ... }:
    {
      # rtkit lets pipewire/pulse acquire realtime scheduling; polkit is needed
      # by the desktop stack (NetworkManager, udisks, GNOME) for privileged
      # actions without a root prompt.
      security.rtkit.enable = true;
      security.polkit.enable = true;

      # The default open-file limit is often too low for development, gaming and
      # other intensive tasks; raise it for the wheel group to avoid "too many
      # open files" errors.
      security.pam.loginLimits = [
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
