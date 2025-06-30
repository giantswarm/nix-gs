{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.7";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-YKaulQbYkzpyT1DIUFOVXdpX9zQLwhlWxjd+HgGrVsQ=";
  };

  vendorHash = "sha256-35o7Wwp/L7OggAf8JWhL/kRAXAJuyPnSfFJolkpaDCo=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
