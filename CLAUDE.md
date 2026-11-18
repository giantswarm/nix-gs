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
- `lib/package-names.nix` - Package list, discovered from the `lib/packages/*.nix` files
- `lib/overlay.nix` - Nixpkgs overlay that adds all packages
- `lib/packages/*.nix` - Individual package definitions using `buildGoModule`

### Package Definitions

All packages in `lib/packages/` follow the same pattern:
- Use `buildGoModule` for Go binaries
- Fetch source from GitHub with `fetchFromGitHub`, tag derived from `version`
- Set `CGO_ENABLED = 0` for static builds
- Include `vendorHash` for Go module dependencies

Each package reads `version`/`hash`/`vendorHash` from a sibling `.json` file. The
`.nix` file spells out the fetcher call; the `.json` file carries only values that
change per release.

`opsctl` is the only private repo. It uses `fetchFromGitHub` with `private = true`
so its source stays a fixed-output derivation -- substitutable, and fetched at
build time rather than during evaluation. Never use `builtins.fetchGit` here: it
fetches at eval time as the invoking user, which breaks unattended rebuilds under
credential-less service accounts and defeats the binary cache. See README
"Private sources" for the `NIX_GITHUB_PRIVATE_*` daemon environment it needs.

To add a package, add `lib/packages/<name>.nix` and `<name>.json`. Nothing else
needs listing: the overlay, the flake's `packages`/`checks` and the `packages`
Home Manager module all derive from `lib/package-names.nix`. Extra `callPackage`
arguments go in the `overrides` set in `lib/overlay.nix`.

To update a package version:
1. Update `version` field (the git tag is derived as `v${version}`)
2. Update `hash` - set to empty string `""` first, build will fail with correct hash
3. Update `vendorHash` - same process, set to `""` and get correct value from build failure

### Home Manager Modules

Located in `nixos/`:
- `projects.nix` - Imports project list from `files/projects.nix`
- `packages.nix` - Installs every package; expects `pkgs` to carry the overlay
- `golang.nix` - Sets `GOPRIVATE=github.com/giantswarm/*`

### Scripts

Nushell scripts in `bin/` for cluster reporting:
- `gs-versions-report.nu` - Report cluster versions across providers
- `gs-cluster-count-per-version.nu` - Count clusters per version
- `gs-clusters-needing-upgrade.nu` - List clusters below the releases that ship a fix

Scripts use shared functions from `lib/scripts/gs.nu` which wraps `opsctl` commands.

## Using as a Dependency

```nix
{
  inputs.nix-gs.url = "github:giantswarm/nix-gs";
  # ... then use nix-gs.overlay or nix-gs.homeManagerModules
}
```

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:1105d646 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
