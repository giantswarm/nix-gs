{ buildGoModule }:
buildGoModule rec {
  pname = "opsctl";
  version = "8.0.0";

  src = builtins.fetchGit {
    url = "git@github.com:giantswarm/${pname}.git";
    ref = "v${version}";
    rev = "454a90f7ca4cebb75bc61bada35773b92c1e6a64";
  };

  vendorHash = "sha256-fd5IXEjG+ypDvu0eLG8LHPvujfqZ48o++gImyAcbjIY=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
