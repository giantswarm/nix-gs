{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "opctl";
  version = "5.3.0";

  vendorHash = "sha256-QOhBXvvvMkLv1GMQzLzGikLilPN/qF7unM02955veEk=";

  CGO_ENABLED = 0;

  nativeBuildInputs = [
    musl
  ];

  ldflags = [
    "-w"
    "-linkmode external"
    "-extldflags '-static -L${musl}/lib'"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
