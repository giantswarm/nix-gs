let
  workDir = "work/giantswarm";
  gitlabRepo = "git.tools.kbee.xyz";

  gsProject = name: {
    name = "gs-${name}";
    path = "${workDir}/gs-${name}";
    repos = [{
      name = "origin";
      url = "git@github.com:giantswarm/${name}.git";
    }];
  };
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
  (gsProject "roadmap")
]
