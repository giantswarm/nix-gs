{ buildGoModule }:
buildGoModule rec {
  pname = "opsctl";
  version = "8.0.0";

  src = builtins.fetchGit {
    url = "git@github.com:giantswarm/${pname}.git";
    ref = "v${version}";
    rev = "b32c3174edfba80b8a3a91114c9dafc85287835f";
  };

  vendorHash = "sha256-TxRvzBZ04uCtrFCuYaLQu4AqiqZO4WyHTGAOhK0uFjE=";

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
