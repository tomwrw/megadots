<p align="center">
  <img src="./assets/megadots.png" width="400" />
</p>

# Introduction

My NixOS configuration, built on the den framework + Home Manager + Flakes. This framework provides libraries that make implementing the dendritic pattern a breeze. I publish this repo to help others, as I found other peoples repos extremely helpful when learning Nix/NixOS. Hopefully I can return the favour.

> **Note:** This is my personal config. Any branch other than `main` should be considered a work in progress. Hardware configs, hostnames, secrets and user attributes are unique to me - you'll need to bring your own.

## About

This is the fourth iteration of my NixOS configuration. I've been daily driving NixOS for nearly 2 years. Most recently, I have dabbled with the dendritic pattern and with the den framework, I have found a suitable home for my configs.

You can find my other configs archived in named branches for review if you want to check out other management styles, like nix-classic and nix-dendritic.

I'm not a developer. I'm a tinkerer with a consultancy job in a technical field who got curious about declarative system management and fell down the NixOS rabbit hole. This project has genuinely brought some fun back in to computing for me.

## Features.

- :desktop_computer: **NixOS** aspects for multiple hosts.
- :house: **Home Manager** as a NixOS module, also supporting standalone mode.
- :ghost: **sops-nix** for secrets management, with dedicated age key support for hosts and users.
- :camera_flash: **Preservation** with root on tmpfs for declarative impermanence.
- :cop: **Secure Boot** via lanzaboote with automatic key generation and enrollment.
- :snowflake: **Flake** with the den framework for modular, composable host and user aspects.
- :floppy_disk: **Disko** for declarative disk partitioning.
- :anger: **CachyOS kernel** for a gaming optimised kernel (opt-in per host).
- :art: **Stylix** for consistent base16 theming across the user environment.
- :rocket: **nixos-anywhere** for bare metal remote deployment.

## Usage.

This configuration has multiple system entry points. At the moment, I am a single user (tomwrw) managing multiple machines.

### Getting Started.

Most day-to-day work goes through the `justfile`. The full deploy flow is a single file that stages keys for shipping to host, deploys the host and then seeds the keys automaticsally

```bash
# Deploy the named host remotely.
just deploy endgame

# Rebuild a remote host (pushes locally-built closure).
just rebuild endgame

# Build a host's closure locally (no activation).
just build endgame

# Run flake checks.
nix flake check
```

### Updating.

To update the flake inputs (e.g., `nixpkgs`), run the following command:

```bash
nix flake update
```

## Community.

I learn by doing. None of this would be possible without the copious ammounts of developers and repos that share their content freely for others like me to disect and study. There are many, but to name a few - shout outs go to:

[ryan4yin](https://github.com/ryan4yin/) for their [awesome book](https://nixos-and-flakes.thiscute.world/) on NixOS (if you haven't started here, then give it a whirl - it really was great) and the [i3 Kickstarter repo](https://github.com/ryan4yin/nix-config/blob/i3-kickstarter/). Both excellent resources to help me understand the power of NixOS.

The majority of my config structure was heavily influenced by the awesome [Misterio77](https://github.com/Misterio77/). Not only did his [Nix Starter Configs](https://github.com/Misterio77/nix-starter-configs) help guide me early on, but his own [Nix Config](https://github.com/Misterio77/nix-config/tree/main) repo was a great inspiration on how to construct and model a modular Nix configuration.

#### And more inspiration...

- Nvim - https://github.com/Nvim (https://github.com/Nvim/snowfall)
- mtrsk - https://github.com/mtrsk (https://github.com/mtrsk/nixos-config)
- runarsf - https://github.com/runarsf (https://github.com/runarsf/dotfiles)
- librephoenix - https://github.com/librephoenix (https://github.com/librephoenix/nixos-config)
- frost-phoenix - https://github.com/Frost-Phoenix (https://github.com/Frost-Phoenix/nixos-config)
