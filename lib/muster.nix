{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.9";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-eGvwiX2/yPrY5Ak7kn8th8uadyIv62Bu5EMryYzmniM=";
  };

  vendorHash = "sha256-GCi5x7TAGXY7iaIQ1wxuEFRHZA066rWTmE45eskHdfM=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
