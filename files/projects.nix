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
    ripple = true;
    repos = [
      {
        name = "origin";
        url = "git@${gitlabRepo}:alex/${name}.git";
      }
      {
        name = "github";
        url = "git@github.com:giantswarm/${name}.git";
        ripple = true;
      }
    ];
  })
  (rec {
    name = "mcp-go";
    path = "${workDir}/${name}";
    repos = [
      {
        name = "origin";
        url = "git@github.com:mark3labs/${name}.git";
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
  "devctl"
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
  "mcp-oauth"
  "mcp-capi"
  "mcp-kubernetes"
  "mcp-prometheus"
  "mcp-opsgenie"
  "mcp-debug"
  "mcp-giantswarm-apps"
  "mcp-teleport"

  "aws-account-setup"
  "giantswarm-aws-account-prerequisites"
])
