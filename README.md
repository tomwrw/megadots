<p align="center">
  <img src="./assets/megadots.png" width="400" />
</p>

# Introduction

My NixOS configuration, built on the classic NixOS + Home Manager + Flake pattern. I publish this to help others, as I found other peoples repos extremely helpful when learning Nix/NixOS. Hopefully I can return the favour.

> **Note:** This is my personal config. Any branch other than `main` should be considered a work in progress. Hardware configs, hostnames, secrets and user attributes are unique to me - you'll need to bring your own.

## About

This is the third iteration of my NixOS configuration. I've been daily driving NixOS for nearly 2 years. Most recently, I have dabbled with the dendritic pattern (you can find this in the commit history tagged as 'dendritic'), but always found myself drawn back to the more traditional modular flake structure influenced by [Misterio77's nix-config](https://github.com/Misterio77/nix-config).

I'm not a developer. I'm a tinkerer with a consultancy job in a technical field who got curious about declarative system management and fell down the NixOS rabbit hole. This project has genuinely brought some fun back in to computing for me.

## Features.

- :desktop_computer: **NixOS** system configuration on multiple hosts.
- :house: **Home Manager** as a NixOS module, with a per-host file per user.
- :ghost: **sops-nix** for secrets management, with age keys derived from SSH host keys.
- :camera_flash: **Preservation** with root on tmpfs for declarative impermanence.
- :cop: **Secure Boot** via lanzaboote with automatic key generation and enrollment.
- :snowflake: **Flake** with modular, composable host and user configs.
- :floppy_disk: **Disko** for declarative disk partitioning.
- :anger: **CachyOS kernel** for a gaming optimised kernel (opt-in per host).
- :art: **Stylix** for consistent base16 theming across the desktop.
- :rocket: **nixos-anywhere** for bare metal remote deployment.
- :white_check_mark: **`nix flake check`** runs formatting, deadnix and statix on the whole tree.

## Usage.

This configuration has multiple system entry points, with Home Manager configured as a NixOS module. At the moment, I am a single user (tomwrw) managing multiple machines. Each host gets its own Home Manager file at `home/tomwrw/<hostname>.nix`, so the same user can have a different feature set per machine.

### Getting Started.

Most day-to-day work goes through the `justfile`. The full deploy flow is two phases - `deploy` installs the OS, `bootstrap` wires up secrets after the host has generated its SSH keys.

```bash
# Build a host's closure locally (no activation).
just build endgame

# Rebuild a remote host (pushes locally-built closure).
just rebuild endgame

# Rebuild on the target itself (one-time bridge before the user is
# trusted with the remote nix daemon, e.g. straight after deploy).
just rebuild-onhost endgame

# Rebuild the local host.
just local

# Phase 1 - bare metal install via nixos-anywhere from the NixOS
# minimal live CD. Prompts for the LUKS passphrase. Secrets do NOT
# work yet at this point.
just deploy endgame

# Phase 2 - register the host's age identity (derived from the SSH
# host key it just generated), copy in user keys, rewrap secrets,
# trigger a rebuild. After this, all secrets decrypt.
just bootstrap endgame

# Format every .nix file in the tree.
nix fmt

# Run flake checks (formatting, deadnix, statix, host eval).
nix flake check
```

### Updating.

To update the flake inputs (e.g., `nixpkgs`), run the following command:

```bash
nix flake update
```

### Configuring sops-nix.

I use sops-nix for secrets in this configuration (user passwords, syncthing keys, etc). Secrets are encrypted with age, and each host has its own age key derived from its SSH host key via `ssh-to-age`. My user age key is derived the same way from `~/.ssh/id_ed25519`.

The flow for adding a new host:

1. Add a new `- &HOST age1...placeholder` entry to `.sops.yaml` under `keys:`, and a matching `- *HOST` reference under the `creation_rules` `age:` list. The bootstrap recipe does an in-place sed on this line, so the placeholder needs to exist for the match to succeed.
2. Run `just deploy HOST`. This installs the OS via nixos-anywhere. The host generates its own SSH host key during install.
3. Run `just bootstrap HOST`. This:
    - Derives your local user age key from `~/.ssh/id_ed25519` if it doesn't already exist.
    - Reads the host's new SSH pubkey over SSH and converts it to an age pubkey.
    - Replaces the placeholder in `.sops.yaml` with the real key.
    - Re-wraps all secrets with `sops updatekeys`.
    - Copies your user SSH key and age key to the host.
    - Triggers a rebuild so the host can decrypt its secrets.

After `bootstrap`, the host is fully functional and `just rebuild HOST` works normally.

### Configuring Secure Boot.

Secure Boot is handled by [lanzaboote](https://github.com/nix-community/lanzaboote) with `autoGenerateKeys` and `autoEnrollKeys` turned on, so the manual `sbctl` ritual is mostly automated. To enable it on a host:

1. Put the host into Secure Boot 'Setup Mode' in the UEFI firmware. On my MSI board there isn't a specific 'Setup Mode' toggle - I set `Factory Keys = disabled` and `Secure Boot Mode = Custom`, then use the resulting custom option to `Delete all UEFI vars`.
2. Add `../../common/optional/secure-boot.nix` to the host's imports (already done for endgame).
3. Rebuild the host. lanzaboote generates the keys, signs the bootloader and reboots once enrollment is complete.
4. Verify with `sudo sbctl status` - Secure Boot should show as enabled (user).

## Hosts.

| System | Description | Type | OS | CPU | GPU |
|---|---|---|---|---|---|
| endgame | My personal desktop | Custom build | NixOS | AMD Ryzen 7800X3D | AMD 9070XT |
| flatmate | My mobile workstation | Surface Pro 7 | NixOS | Intel i7-1065G7 | Intel iGPU |
| spectre | My test VM | QEMU VM | NixOS | Host passthrough | virtio-gpu |

I have a single user that I manage through Home Manager (tomwrw). You may add additional users or rename mine to inherit my existing settings - though you'll need to replace the age keys in `.sops.yaml` with your own, and re-create the `secrets/secrets.yaml` file with your own paths and secrets.

### File structure.

I use the following structure to organise my configurations.

```
.
├── flake.nix             # My flake. Entry point for system configs.
├── flake.lock            # Pinned flake inputs.
├── justfile              # Deploy, bootstrap, build and rebuild recipes.
├── .sops.yaml            # sops-nix recipients and creation rules.
├── assets                # Static assets used by the config.
│   └── wallpaper         # Wallpapers used by my stylix theme.
├── home                  # Home Manager configs, one folder per user.
│   └── tomwrw            # My primary user.
│       ├── global        # Global Home Manager configs, applied for the user on every host.
│       ├── features      # Optional Home Manager configs, selectively imported per host.
│       │   ├── cli           # Terminal tooling (ghostty, zsh, git, btop, etc.).
│       │   ├── comms         # Messaging apps (signal, element, vesktop, whatsapp).
│       │   ├── desktop       # Desktop-environment specific config.
│       │   │   ├── common    # Shared desktop config (stylix, etc.).
│       │   │   └── gnome     # GNOME-specific config and extensions.
│       │   ├── development   # Editors and AI tooling (vscodium, cursor, claude-code, gemini).
│       │   ├── media         # Media apps (spotify, ente).
│       │   ├── productivity  # Browser, notes, etc. (firefox, obsidian, joplin).
│       │   ├── security      # User-scoped security (sops, proton suite, ente-auth).
│       │   └── services      # User services (syncthing, filen).
│       ├── endgame.nix   # Per-host Home Manager entry point (imports features).
│       ├── flatmate.nix
│       └── spectre.nix
├── hosts                 # NixOS host configs.
│   ├── common            # Shared NixOS config.
│   │   ├── global        # Global system configs, applied on every host.
│   │   ├── optional      # Optional system configs, selectively imported per host.
│   │   │   └── desktop   # Optional desktop-environment configs (e.g. gnome).
│   │   └── users         # Per-user system-level config.
│   │       └── tomwrw    # My user account, groups, sops password binding.
│   └── nixos             # NixOS hosts managed by this repo.
│       ├── endgame       # My primary desktop.
│       ├── flatmate      # My mobile device (Surface Pro 7).
│       └── spectre       # My test VM.
├── modules               # Reusable modules I'd be happy to share.
│   ├── home-manager      # Custom-written Home Manager modules.
│   └── nixos             # Custom-written NixOS modules.
├── overlays              # Overlays for patches and overrides.
├── pkgs                  # Custom packages built from this repo.
└── secrets               # sops-encrypted secrets.
    └── secrets.yaml
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
