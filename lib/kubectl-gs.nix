{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "kubectl-gs";
  version = "4.8.1";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YtlqmM6dSKI3QIW7cE0wwoDY1L5ciNqyHUwpoUFJgJQ=";
  };

  vendorHash = "sha256-OY8Khe9nCLukpLluZXCuTPdynUc3bN9ig5Zm9qJ9tfk=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
