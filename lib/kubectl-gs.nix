{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.55.0";

  vendorHash = "sha256-Bb+EcjM9BsHxhlXLJCCVP0UKbpHbrIm0sclyLkisPbc=";

  CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
