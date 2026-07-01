# NixConfig Conventions for LLMs

## Key Features and Principles

- Home Manager runs as a NixOS module, with a per-host file per user. This is the supported model. Standalone Home Manager on non-NixOS hosts is not currently supported: the impermanence `home.persistence` module asserts it is run as a NixOS module, so the feature modules cannot evaluate standalone as-is.
- All user feature modules should live in an appropriate, already defined directory such as cli, productivity etc.
- No secret material should ever be store in this repo.
- This repo will be public facing and used to showcase what a well-maintained config should look like.
- I prefer nixfmt over any other formatter.
- Always use the most up to date documents for referencing.
- Ask me questions to clarify if needed.
- I prefer simplicity over complexity.

## Commit Messages

Conventional commits: `type: Description.`

- `type`: `feat`, `fix`, `refactor`, `chore`, `wip`
- `type` is lowercase, colon at the end.
- `description` is sentance case, period at the end.

### Flake Lock Bumps

When describing a `flake.lock` bump (e.g. after `nix flake update <input>`), summarize
what actually changed in the bumped input(s), not just the revision hashes:

1. Get the old → new revisions from the `nix flake update` output or `flake.lock` diff.
2. Fetch the upstream changelog between them (`gh`/GitHub compare API, or a local clone
   in `/tmp`): `curl -s https://api.github.com/repos/<owner>/<repo>/compare/<old>...<new>`.
3. In the commit body, note the short hash range and a brief bullet list of the
   meaningful changes (commits/files), so the diff is reviewable without leaving the repo.

Example:

```
chore: Bump flake.

Update website from f6c09b0b to 70386bb7 (2 commits, docs-only):
- add _src/llms.txt
- remove stale _src/portfolio.md and its references in llms.txt
```

## Directory Structure

```
.
.
├── flake.nix                 # My flake. Entry point for system configs.
├── flake.lock                # Pinned flake inputs.
├── justfile                  # Deploy, build, rebuild and enroll-fido2 recipes.
├── .sops.yaml                # sops-nix recipients and creation rules.
├── assets                    # Static assets used by the config.
│   └── wallpaper             # Wallpapers used by my stylix theme.
├── home                      # Home Manager configs, one folder per user.
│   └── tomwrw                # My primary user.
│       ├── global            # Global Home Manager configs, applied for the user on every host.
│       ├── features          # Optional Home Manager configs, selectively imported per host.
│       │   ├── cli           # Terminal tooling (ghostty, zsh, git, btop, etc.).
│       │   ├── comms         # Messaging apps (signal, element, vesktop, whatsapp).
│       │   ├── desktop       # Desktop-environment specific config.
│       │   │   ├── common    # Shared desktop config (stylix, etc.).
│       │   │   └── gnome     # GNOME-specific config and extensions.
│       │   ├── development   # Editors and AI tooling (vscodium, cursor, claude-code, gemini).
│       │   ├── media         # Media apps (spotify, ente).
│       │   ├── productivity  # Browser, notes, etc. (firefox, obsidian, joplin).
│       │   ├── security      # User-scoped security (proton suite, ente-auth).
│       │   └── services      # User services (filen).
│       ├── endgame.nix       # Host Home Manager entry point (imports features).
│       ├── flatmate.nix      # Host Home Manager entry point (imports features).
│       └── spectre.nix       # Host Home Manager entry point (imports features).
├── hosts                     # NixOS host configs.
│   ├── common                # Shared NixOS config.
│   │   ├── global            # Global system configs, applied on every host.
│   │   ├── optional          # Optional system configs, selectively imported per host.
│   │   │   └── desktop       # Optional desktop-environment configs (e.g. gnome).
│   │   └── users             # Per-user system-level config.
│   │       └── tomwrw        # My user account, groups, sops password binding.
│   └── nixos                 # NixOS hosts managed by this repo.
│       ├── endgame           # My primary desktop.
│       ├── flatmate          # My mobile device (Surface Pro 7).
│       └── spectre           # My test VM.
├── modules                   # Reusable modules I'd be happy to share.
│   ├── home-manager          # Custom-written Home Manager modules.
│   └── nixos                 # Custom-written NixOS modules.
├── overlays                  # Overlays for patches and overrides.
├── pkgs                      # Custom packages built from this repo.
└── secrets                   # sops-encrypted secrets.
    ├── endgame.yaml          # Secrets for the host endgame.
    ├── flatmate.yaml         # Secrets for the host flatmate.
    └── spectre.yaml          # Secrets for the host spectre.
```

## Code Style

- **Formatter**: nixfmt (`nix fmt <file>`). ALWAYS format after edits. Never format unmodified files.
- **Indentation**: 1 tab.
- **Line endings**: LF, final newline, trimmed trailing whitespace.
- **Nix conventions**:
  - Top-level modules are functions taking `{pkgs, lib, config, inputs, ...}`.
  - Use `lib` from `nixpkgs.lib // home-manager.lib` (merged, already in `outputs.lib`).
  - Feature-flag modules use a `default.nix`.
  - Prefer `lib.mkOption` / `lib.mkEnableOption` for new options.

## Secrets

- Managed with **sops-nix**, keys defined in `.sops.yaml`.
- One type of secret file:
  - `secrets/{hostname}.yaml` -- per-host, encrypted to that host and user tomwrw's Token2 keys (age).
- **Never** read secrets into context. Ask the user to do it.
- **Never** store secret material in this repo.

## Building and Deploying

All workflows go through the `justfile`:

- `just build <host>` -- build a host's closure locally, no activation.
- `just rebuild <host>` -- rebuild a remote host (pushes a locally-built closure).
- `just rebuild-onhost <host>` -- build on the target itself; the one-time bridge before the user is trusted with the remote nix daemon (e.g. straight after a fresh deploy).
- `just local` -- rebuild the local host.
- `just deploy <host>` -- bare-metal install via `nixos-anywhere`. Single phase: it also seeds the host's pre-generated age key and FIDO2 key handles from the USB stick via `--extra-files`, so secrets decrypt on first boot. There is no separate bootstrap step.
- `just enroll-fido2 <host>` -- enrol the plugged-in Token2 in the host's LUKS header (once per token; the passphrase slot stays as a fallback).

Risky changes (anything touching disko layout, the initrd rollback service, LUKS/PAM, or kernel hardening) must be rolled out `spectre` (disposable VM) first, then `flatmate`, then `endgame`.

### Post-deploy verification

- `nix flake check` and `just build <host>` only prove the config *evaluates and builds* - they do not prove runtime behaviour. Changes to hardening, the rollback service, LUKS or PAM must be checked on a live boot.
- After a hardening or services change, confirm on the target: `aa-status` (AppArmor loaded), `systemctl status fail2ban`, `cat /sys/kernel/security/lockdown`, and spot-check a couple of sysctls (`sysctl kernel.kptr_restrict`).
- After an impermanence change, reboot at least twice and confirm `/persist` survives and the declared persistence paths are present.

## Nix eval

- Format and check before every commit: `nix fmt -- --no-cache` then `nix flake check` (runs nixfmt, deadnix and statix, and evaluates every host).
- To inspect a value without building, use `nix eval .#nixosConfigurations.<host>.config.<option.path>`.
- `nix flake check` evaluating green is necessary but not sufficient for boot-affecting changes - see post-deploy verification above.
