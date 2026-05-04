{
  nixpkgs.config.allowUnfreePackages = [
    "claude-code"
    "claude-monitor"
  ];

  flake.modules.homeManager.pc =
    { pkgs, ... }:
    {
      home.packages = [ 
        pkgs.claude-code
        pkgs.claude-monitor
      ];
    };
}