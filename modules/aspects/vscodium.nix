_: {
  den.aspects.vscodium.homeManager = _: {
    programs.vscodium.enable = true;

    # VSCodium force-injects its own SSH_ASKPASS (a yes/no quickpick that can't
    # take a FIDO2 PIN), which breaks commit signing. Turning it off lets git
    # fall through to the system askpass (seahorse). Merges with stylix's
    # settings into the same managed settings.json.
    programs.vscodium.profiles.default.userSettings."git.useIntegratedAskPass" = false;
  };
}
