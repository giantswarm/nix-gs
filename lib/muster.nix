{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.51";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-X5jLAnvk589/MSrZtztgcEPzlo99RZ+LuqvIT+LlMwU=";
  };

  vendorHash = "sha256-dLXlk7xKzsVV+3zMM/o4J6NRqYY+Ulhq1EnGTwWOHcQ=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
