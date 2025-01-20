{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "4.7.0";

  vendorHash = "sha256-LRT/SUYTpPLzaTmBb1rEVW9DlPANTgGsIWPKzWkhX4A=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
