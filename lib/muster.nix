{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.44";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-20kD/bPMFySPLeL1x61UDDaKfoNXvSeWRJUt6Vv44Nc=";
  };

  vendorHash = "sha256-dLXlk7xKzsVV+3zMM/o4J6NRqYY+Ulhq1EnGTwWOHcQ=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
