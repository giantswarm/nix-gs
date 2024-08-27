{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "4.0.0";

  vendorHash = "sha256-/QMIkcElG0JsFzXxpwwV4DAMYHpZ+xudGJqAf8bwMKg=";

  CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
