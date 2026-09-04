{ den, ... }:
{
  den.aspects.gaming = {
    # The host half: system services and programs.
    includes = [
      den.aspects.steam
      den.aspects.sunshine
    ];

    # The user half, given to every user on a host taking this role. These used
    # to hang off provides.<hostname> in the user aspect, which meant a second
    # gaming host was a user-file edit and renaming a host switched them off
    # silently - den matches provides.<name> against the host name and says
    # nothing when it does not match.
    provides.to-users.includes = [
      den.aspects.emulation
      den.aspects.mangohud
      den.aspects.minecraft
    ];
  };
}
