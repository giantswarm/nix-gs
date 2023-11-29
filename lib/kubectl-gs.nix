{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.48.0";

  vendorHash = "sha256-hxi4lwvX4k6aL7mqxBnfoPLgpP8v2m9vi5tUuqom4vQ=";

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
