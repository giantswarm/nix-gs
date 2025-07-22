{ pkgs, buildGoModule }:
buildGoModule rec {
  pname = "muster";
  version = "0.0.31";

  src = pkgs.fetchFromGitHub {
    owner = "giantswarm";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-TE0VkLSwefABXXS0lQeqr6CKi5sLtMdzvkp16IT7XLg=";
  };

  vendorHash = "sha256-yTmOzZaFZEm+Noz2SF621e/XNQYAtsuwSaZVB4Bc+fw=";

  doCheck = false;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-w"
  ];
}
