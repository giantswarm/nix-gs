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

## Run GS scripts

### Versions report

```
./bin/gs-versions-report.nu
```
