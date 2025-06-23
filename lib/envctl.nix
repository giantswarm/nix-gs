{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "envctl";
  version = "0.0.12";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = "envctl";
    rev = "v${version}";
    hash = "sha256-AqB7+J9l5rZ1gvE0HoGo837BNAQ/PSA7iCT24n5O6L4=";
  };

  vendorHash = "sha256-D9/UE5iHLQtykVJi5HL7ioYM6fZUDCwk5oA+WsAPzKM=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
