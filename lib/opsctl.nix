{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "6.2.1";

  vendorHash = "sha256-jhjIgJ06bHvzVd4eHykTNskAJxxnVhVOreFI6cshRJU=";

  CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
