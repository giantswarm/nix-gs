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
  "docs"
  "handbook"
  "debug"
  "envctl"
  "opsctl"
  "architect"
  "releases"
  "mc-bootstrap"
  "cluster"
  "cluster-aws"
  "cluster-api-provider-aws"
  "cluster-azure"
  "cluster-api-provider-azure"
  "haive-sprint-incident-analysis"
  "oka"
  "operatorkit"
  "backoff"
  "exporterkit"
  "k8sclient"
  "microerror"
  "micrologger"
  "cluster-apps-operator"

  "muster"
  "mcp-capi"
  "mcp-kubernetes"
  "mcp-prometheus"
  "mcp-opsgenie"
  "mcp-debug"
  "mcp-giantswarm-apps"
  "mcp-teleport"
])
