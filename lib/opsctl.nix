{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "6.4.0";

  vendorHash = "sha256-JjrE2zsC8bvtdwCbPwE342c/f/errZHtQ02P2nE4CHw=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
