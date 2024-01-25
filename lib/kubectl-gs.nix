{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.51.0";

  vendorHash = "sha256-eQQv07rJxDH03QKyKNoAbWbcDDjn/GAxxm6rCTBtElc=";

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
