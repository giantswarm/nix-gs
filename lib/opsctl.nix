{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "opctl";
  version = "6.0.0";

  vendorHash = "sha256-hxDoRISqrLQplytfxV2SIAVWwyVsujsezKPVR04XGn0=";

  CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
