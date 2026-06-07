{ ... }:
{
  # Bitwarden CLI only. The desktop app (bitwarden-desktop) is intentionally
  # omitted: it bundles an EOL Electron (electron-39, flagged insecure), and the
  # day-to-day GUI is the Firefox extension (see firefox.nix). `bw` is native.
  den.aspects.bitwarden.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.bitwarden-cli ];
    };
}
