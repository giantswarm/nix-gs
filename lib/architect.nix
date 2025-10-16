{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "architect";
  version = "7.2.1";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-cAB3h8BR9YLh/Lv69bRja7uG15LAprr/h9iFcGsMEPs=";
  };

  vendorHash = "sha256-BhD1tBn2CegbbQmgjTPtEJ1pZvlIg1manMShp/Tnosw=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/architect/pkg/project.gitSHA=${src.rev}'"
  ];
}
