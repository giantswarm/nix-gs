{ buildGoModule }:
let
  meta = builtins.fromJSON (builtins.readFile ./konfigure.json);
in
buildGoModule rec {
  pname = "konfigure";
  version = meta.version;

  src = builtins.fetchGit {
    url = meta.url;
    ref = "v${version}";
    rev = meta.rev;
  };

  vendorHash = meta.vendorHash;

  env.CGO_ENABLED = 0;

  doCheck = false;

  ldflags = [
    "-w"
  ];
}
