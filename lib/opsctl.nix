{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "6.3.0";

  vendorHash = "sha256-7jzlg1VgpA12IkTWTtoFYmjB7Cgondwg8ltiEFtgtBY=";

  CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
