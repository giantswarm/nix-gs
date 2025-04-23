let
  workDir = "work/giantswarm";
  gitlabRepo = "git.tools.kbee.xyz";
in [
  (rec {
    name = "nix-gs";
    path = "${workDir}/${name}";
    repos = [
      {
        name = "origin";
        url = "git@${gitlabRepo}:alex/${name}.git";
      }
      {
        name = "github";
        url = "git@github.com:giantswarm/${name}.git";
      }
    ];
  })
]
