{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "6.2.0";

  vendorHash = "sha256-IsuWmEzA724RtWF3Efyr4fTFVLQyFQ7FH4Iz6n+SzlA=";

  CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
