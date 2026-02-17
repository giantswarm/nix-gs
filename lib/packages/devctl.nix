{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./devctl.json);
in
buildGoModule rec {
  pname = "devctl";
  version = meta.version;

  src = pkgs.fetchFromGitHub {
    owner = meta.owner;
    repo = meta.repo;
    rev = "v${version}";
    hash = meta.hash;
  };

  vendorHash = meta.vendorHash;

  env.CGO_ENABLED = 0;

  doCheck = false;

  # Generate .template.sha files expected by //go:embed directives.
  # The build-time generator uses git history which is unavailable in the sandbox,
  # so we create them with a URL pointing to the release tag.
  preBuild = ''
    for tpl in $(find . -name '*.template'); do
      echo -n "https://github.com/giantswarm/devctl/blob/v${version}/''${tpl#./}" > "''${tpl}.sha"
    done
  '';

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/devctl/v7/pkg/project.gitSHA=${src.rev}'"
  ];
}
