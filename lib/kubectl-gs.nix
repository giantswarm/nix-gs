{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "4.8.0";

  vendorHash = "sha256-VtbDi9WhVudcjB4XbUY9h6KKYiFafIf0itvxoWlxBZM=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
