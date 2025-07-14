{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.23";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-6x0HjkYwsAof+xzOjvYRsi2joroTaJP9cfZvLjg0W+Y=";
  };

  vendorHash = "sha256-pc2TPvWcnbD4mSyJx3/PRvWPycgfFAyLWSVU7m6Y2vA=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
