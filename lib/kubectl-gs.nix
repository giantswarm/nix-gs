{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.45.3";

  vendorSha256 = "sha256-xXbzm9uDi9fXRJfJAPSIK0NxG31JrtisFjXAjn44oEQ=";

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
