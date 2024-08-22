{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "3.2.0";

  vendorHash = "sha256-AZ5R0SDv5Rn79ZquNFVQzq/v12Urf9GtacjUye8GvNI=";

  CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
