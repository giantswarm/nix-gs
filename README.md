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
