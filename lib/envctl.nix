{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "envctl";
  version = "0.0.13";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-7gnv4AYjIXf4pdpUEKn8+0nGgACroVv0mw79kffBv8A=";
  };

  vendorHash = "sha256-D9/UE5iHLQtykVJi5HL7ioYM6fZUDCwk5oA+WsAPzKM=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
