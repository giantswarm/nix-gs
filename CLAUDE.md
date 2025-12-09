# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Nix flake that provides Giant Swarm-specific tools and configurations. It packages several Go CLI tools and provides Home Manager modules for NixOS/home-manager users.

## Build Commands

Build a specific package:
```
nix build -v -L .#<package>
```

Available packages: `opsctl`, `kubectl-gs`, `muster`, `envctl`, `architect`

Run built binary:
```
./result/bin/<binary> --help
```

## Architecture

### Flake Structure

- `flake.nix` - Main entry point exposing packages and Home Manager modules
- `lib/overlay.nix` - Nixpkgs overlay that adds all packages
- `lib/*.nix` - Individual package definitions using `buildGoModule`

### Package Definitions

All packages in `lib/` follow the same pattern:
- Use `buildGoModule` for Go binaries
- Fetch source from GitHub with `fetchFromGitHub` (or `builtins.fetchGit` for private repos like opsctl)
- Set `CGO_ENABLED = 0` for static builds
- Include `vendorHash` for Go module dependencies

To update a package version:
1. Update `version` field
2. Update `rev` in `src` (if using fetchFromGitHub)
3. Update `hash` in `src` - set to empty string `""` first, build will fail with correct hash
4. Update `vendorHash` - same process, set to `""` and get correct value from build failure

### Home Manager Modules

Located in `nixos/`:
- `projects.nix` - Imports project list from `files/projects.nix`
- `golang.nix` - Sets `GOPRIVATE=github.com/giantswarm/*`

### Scripts

Nushell scripts in `bin/` for cluster reporting:
- `gs-versions-report.nu` - Report cluster versions across providers
- `gs-cluster-count-per-version.nu` - Count clusters per version

Scripts use shared functions from `lib/scripts/gs.nu` which wraps `opsctl` commands.

## Using as a Dependency

```nix
{
  inputs.nix-gs.url = "github:giantswarm/nix-gs";
  # ... then use nix-gs.overlay or nix-gs.homeManagerModules
}
```
