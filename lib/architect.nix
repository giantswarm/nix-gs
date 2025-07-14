{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "architect";
  version = "7.0.2";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-Dx92h2e21f5eKmvG/3tPYaubKE+u0WrFSYJDu916Hh8=";
  };

  vendorHash = "sha256-UR8dPcEwIgGzDLsBLgtDYhZs9YK+JZ3eBgj8O/WdZj0=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/architect/pkg/project.gitSHA=${src.rev}'"
  ];
}
