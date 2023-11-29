module opsctl {
  export def "gs mcs" [
      --provider: string = ''
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    (opsctl list installations --provider $provider --pipeline $pipeline --customer $customer
      | lines
      | skip 1
      | split column --regex '\s\s+'
      | rename codename provider pipeline customer ae hostname created repository)
  }

  export def "gs mcs aws" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'aws' --pipeline $pipeline --customer $customer
  }

  export def "gs mcs azure" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'azure' --pipeline $pipeline --customer $customer
  }

  export def "gs mcs capa" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'capa' --pipeline $pipeline --customer $customer
  }

  export def "gs mcs capz" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'capz' --pipeline $pipeline --customer $customer
  }
}

use opsctl *
use std log


def clusters-with-initiator-app [mc: string] {
  let appsFile = $"($mc)_apps.json"

  if not ($appsFile | path exists) {
    do -c { opsctl login $mc }
    kubectl get apps -A --output json out> $appsFile
  }

  (open $appsFile
    | get items
    | where {|it| $it.spec.name == "k8s-initiator-app"}
    | each {|it| $it.metadata.namespace}
    | sort)
}

def initiator-app-config [mc: string, wc: string] {
  let appsFile = $"($mc)_($wc)_apps.json"
  let configMapsFile = $"($mc)_($wc)_configmaps.json"
  let resultsFile = $"($mc)_($wc)_initiator_config.json"

  log info $"downloading initiator app config for ($mc)/($wc) to ($resultsFile)..."

  if not (($appsFile | path exists) and ($configMapsFile | path exists)) {
    do -c { opsctl login $mc }
    kubectl --namespace $wc get apps --output json out> $appsFile
    kubectl --namespace $wc get configmaps --output json out> $configMapsFile
  }

  let apps = (open $appsFile
    | get items
    | where {|it| $it.spec.name == "k8s-initiator-app"})

  let configMaps1 = $apps | each {|it| $it.spec.config.configMap?} | select name namespace;
  let configMaps2 = $apps | each {|it| $it.spec.extraConfigs?} | flatten | select name namespace;

  let configMaps = ($configMaps1 | append $configMaps2) | sort-by name | uniq


  let configs = open $configMapsFile | get items
  ($configMaps
    | each {|it| get-config $configs $it}
    | each {|it| {name: $it.metadata.name, data: $it.data?}}
    | to json
    | save -f $resultsFile)
}

def get-config [
    configs: list<record>,
    config: record<name: string, namespace: string>
  ]: nothing -> list<record> {
  $configs | where {|it| $it.metadata.name == $config.name and $it.metadata.namespace == $config.namespace}
}

def save-initiator-configs [mc: string] {
  log info $"downloading initiator app config for ($mc)..."
  (clusters-with-initiator-app $mc
    | each {|wc| initiator-app-config $mc $wc})
  null
}
