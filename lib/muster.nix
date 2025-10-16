{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.65";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-ZKApWzRaSYb05lOM6NvanOPDSRlEZMXc3+4QWBdWlsA=";
  };

  vendorHash = "sha256-YSgdxcapR22oD2fEs+ZhFfOUbckUg4LYKDJKBw7iljQ=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
