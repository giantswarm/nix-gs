{ src, buildGoModule }:
buildGoModule {
  inherit src;

  pname = "opsctl";
  version = "7.0.1";

  vendorHash = "sha256-skZyS/1vcreeiaUrhLqgO2jSTAPfk8V4rPghO1YWXcw=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
