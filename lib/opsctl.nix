{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "7.2.2";

  vendorHash = "sha256-fd5IXEjG+ypDvu0eLG8LHPvujfqZ48o++gImyAcbjIY=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
