{ pkgs, src, buildGoModule, musl }:
buildGoModule {
  inherit src;

  pname = "kubectl-gs";
  version = "2.52.1";

  vendorHash = "sha256-Uv66rm6Z0gZNUMVF0CeYa+Tdrj8akFKa6xJ7xmcgVx0=";

  CGO_ENABLED = 0;

  doCheck = false;

  nativeBuildInputs = [
    musl
  ];

  ldflags = [
    "-w"
    "-linkmode external"
    "-extldflags '-static -L${musl}/lib'"
    "-X 'github.com/giantswarm/kubectl-gs/v2/pkg/project.gitSHA=${src.rev}'"
  ];
}
