{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "kubectl-gs";
  version = "4.8.0";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-DWAIYX0r8U/wR8broKlSCn9Pl8/o1moWDpkVKjktXRQ=";
  };

  vendorHash = "sha256-VtbDi9WhVudcjB4XbUY9h6KKYiFafIf0itvxoWlxBZM=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
