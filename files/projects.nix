let
  gitlabRepo = "git.tools.kbee.xyz";

  # `path` is the grove-relative container: nix-home resolves it as
  # `~/grove/<path>`. It is NOT a $HOME-relative work directory — that flat
  # layout is retired, and nix-home guards against its `work/` spelling
  # returning. Group the Giant Swarm set under `gs/`, the same way the
  # OpenWrt family sits under `router/`.
  groupDir = "gs";

  gsProject = name: {
    name = "gs-${name}";
    path = "${groupDir}/${name}";
    repos = [{
      name = "origin";
      url = "git@github.com:giantswarm/${name}.git";
    }];
  };
in [
  (rec {
    name = "nix-gs";
    # Top-level, alongside nix-forge-gs — this is tooling, not a GS service repo.
    path = name;
    # Cascade membership is a tag, not a boolean: nix-home's projectSubmodule
    # declares `tags`, and ripple selects on `"ripple" in tags`. A bare
    # `ripple = true` here fails nix-home's eval outright.
    tags = [ "ripple" ];
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
  (rec {
    name = "mcp-go";
    # mark3labs upstream, not a Giant Swarm repo — grouped with the other
    # third-party checkouts rather than under gs/.
    path = "opensource/${name}";
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
  "mctl"
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

  "kaas"

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
