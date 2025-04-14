{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "7.2.1";

  vendorHash = "sha256-8uzN0pX099IH1tByb4H5uSrR1o7JT4JwARy9cSMXJ4E=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
