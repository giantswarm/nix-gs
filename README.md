## Test packge builds

### `opsctl`

Build the package:
```
nix build -v -L .#opsctl
```

Run the binary:
```
./result/bin/opsctl --help
```

### `kubectl-gs`

Build the package:
```
nix build -v -L .#kubectl-gs
```

Run the binary:
```
./result/bin/kubectl-gs --help
```


## Example flake

```
{
  description = "Example flake";

  inputs = {
    systems.url = "github:nix-systems/default";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    nix-gs = {
      url = "github:giantswarm/nix-gs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {self, flake-utils, nixpkgs, nix-gs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [nix-gs.overlay];
        };
      in {
        packages = {
          inherit (pkgs) opsctl kubectl-gs;
        };
    });
}
```


## Update packages

### Using the update script

Update all packages to their latest versions:
```
./bin/update-packages.nu
```

Update a specific package:
```
./bin/update-packages.nu kubectl-gs
```

Preview changes without applying them:
```
./bin/update-packages.nu --dry-run
```

List available packages:
```
./bin/update-packages.nu --list
```

### Manual update

If the script fails, you can update packages manually:

1. Edit `lib/packages/<package>.json`
2. Update the `version` field
3. Set `hash` and `vendorHash` to empty strings `""`
4. Run `nix build .#<package>` - it will fail with the correct hash
5. Copy the hash from the error output into the JSON file
6. Run the build again - it will fail with the correct vendorHash
7. Copy the vendorHash and run the build to verify


## Private sources

`opsctl` lives in a private repository. It is still fetched the same way as every
other package -- `fetchFromGitHub`, with `private = true` -- so the source is a
fixed-output derivation: pinned by `hash`, fetched at build time, and
substitutable from a binary cache.

That last property is the point. Any host that can reach a cache holding the
source (or the built `opsctl`) needs **no GitHub credentials at all**, and
evaluation never touches the network. Unattended rebuilds under a service account
work.

Credentials are only needed to *realise* the source from scratch -- the first
build of a new version, or a `hash` update. `private = true` authenticates with a
netrc built from two environment variables:

```
NIX_GITHUB_PRIVATE_USERNAME   your GitHub username
NIX_GITHUB_PRIVATE_PASSWORD   a token with read access to giantswarm/opsctl
```

These must be set for the process that **runs the build**. With multi-user Nix
that is the `nix-daemon`, not your shell -- exporting them in your terminal has
no effect. On NixOS, keep the token out of the world-readable Nix store by
passing it through a file:

```nix
systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/run/secrets/nix-github-private";
```

where that file contains the two `NAME=value` lines. Then
`systemctl restart nix-daemon`.

Without them, the build fails in `netrcPhase` naming both variables. Everything
up to that point -- evaluation, `nix flake check` on other packages, and any
build whose source is already in the store or a cache -- is unaffected.

### Why not `builtins.fetchGit`

`opsctl` used to use it. `builtins.fetchGit` fetches during *evaluation*, in the
client process, using the invoking user's ambient git credentials. That makes
every evaluator need GitHub access, makes the result non-substitutable, and gives
different results for different users on one machine. An unattended
`nixos-rebuild` running as a credential-less service account fails before any
build starts, with a `could not read Username for 'https://github.com'` buried in
an unrelated evaluation trace. Do not reintroduce it.


## Run GS scripts

### Versions report

```
./bin/gs-versions-report.nu
```

### Count clusters per version for all MCs

```
./bin/gs-cluster-count-per-version.nu
```

### Count clusters per version for a single MC

```
./bin/gs-cluster-count-per-version.nu --mc gazelle
```
