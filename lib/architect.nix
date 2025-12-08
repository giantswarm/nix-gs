{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "architect";
  version = "7.3.0";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-vLZ6z9OwgWEVrG+S2ICzhUWeUjG9UV4dsgnHpn1WJ5s=";
  };

  vendorHash = "sha256-rFtIouWKAGe1U9Yam3/gzZ9gfGlb63E+1TpXjg30bkw=";

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/architect/pkg/project.gitSHA=${src.rev}'"
  ];
}
