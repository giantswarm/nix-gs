{ pkgs, buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./opsctl.json);
in
buildGoModule rec {
  pname = "opsctl";
  version = meta.version;

  # opsctl is the one private repo here, but it is still fetched as a fixed-output
  # derivation like every other package. `private = true` makes fetchFromGitHub go
  # through the API tarball endpoint and write a netrc from
  # NIX_GITHUB_PRIVATE_USERNAME/PASSWORD, which the *building* process needs (the
  # nix-daemon, in multi-user mode) -- see README "Private sources".
  #
  # Do not go back to builtins.fetchGit: that fetches during evaluation, in the
  # client process, using the invoking user's ambient git credentials. Every
  # evaluator then needs GitHub access and the source is never substitutable, so
  # unattended rebuilds under a credential-less service account fail before any
  # build starts.
  src = pkgs.fetchFromGitHub {
    owner = meta.owner;
    repo = meta.repo;
    rev = "v${version}";
    hash = meta.hash;
    private = true;
  };

  vendorHash = meta.vendorHash;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
    "-X 'github.com/giantswarm/opsctl/v5/pkg/project.gitSHA=${src.rev}'"
  ];
}
