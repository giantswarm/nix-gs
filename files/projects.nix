let
  workDir = "work/giantswarm";
  gitlabRepo = "git.tools.kbee.xyz";

  gsProject = name: {
    name = "gs-${name}";
    path = "${workDir}/${name}";
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
] ++ (builtins.map gsProject [
  "roadmap"
  "giantswarm"
  "cluster-aws"
  "cluster-api-provider-aws"
  "cluster-azure"
  "cluster-api-provider-azure"
])
