{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.49.1";

  vendorHash = "sha256-VDkoh16q4BpdHmWRdi93LmGwRZY54Zb6Twe/hzLtX2A=";

  CGO_ENABLED = 0;

  doCheck = false;

  nativeBuildInputs = [
    musl
  ];

  ldflags = [
    "-w"
    "-linkmode external"
    "-extldflags '-static -L${musl}/lib'"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
