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

  export def "gs mcs capv" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'vsphere' --pipeline $pipeline --customer $customer
  }

  export def "gs mcs capvcd" [
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    gs mcs --provider 'cloud-director' --pipeline $pipeline --customer $customer
  }
}

module gs {
  use opsctl *

  export def clusters [mc: string, customer: string] {
    let cacheDir = [$env.HOME ".cache" "gs-clusters"] | path join
    if not ($cacheDir | path exists) {
      mkdir $cacheDir
    }

    let clustersFile = [$cacheDir $"($mc)_clusters.json"] | path join

    if not ($clustersFile | path exists) {
      do -c { tsh kube login $mc }
      kubectl get clusters.cluster.x-k8s.io -A --output json out> $clustersFile
    }

    (open $clustersFile
      | get items
      | each {|it|
          {
            name: $it.metadata.name,
            kind: $it.kind,
            app: $it.metadata.labels."app"?,
            version: (extract-version $it),
          }
        }
      | where {|it| $it.app in ["cluster-aws", "cluster-azure", "cluster-vsphere", "cluster-cloud-director"] }
      | insert mc $mc
      | insert customer $customer
      | each {|it| $it | insert provider (get-provider $it.app)}
      | each {|it| $it | insert v29 (is-v29 $it.version)}
      | each {|it| $it | insert v30 (is-v30 $it.version)}
      | each {|it| $it | insert v31 (is-v31 $it.version)}
      | each {|it| $it | insert v32 (is-v32 $it.version)}
      | sort)
  }

  def extract-version [cr: record]: nothing -> string {
    let version = $cr.metadata.labels."release.giantswarm.io/version"?
    if $version == null {
      "unknown"
    } else {
      $version
    }
  }

  def get-provider [app: string]: nothing -> string {
    match $app {
      "cluster-aws" => "capa",
      "cluster-azure" => "capz",
      "cluster-vsphere" => "capv",
      "cluster-cloud-director" => "capvcd",
      _ => "unknown",
    }
  }

  def is-v29 [version: string]: nothing -> bool {
    ($version | str starts-with "29.") or ($version | str starts-with "30.") or ($version | str starts-with "31.") or ($version | str starts-with "32.")
  }

  def is-v30 [version: string]: nothing -> bool {
    ($version | str starts-with "30.") or ($version | str starts-with "31.") or ($version | str starts-with "32.")
  }

  def is-v31 [version: string]: nothing -> bool {
    ($version | str starts-with "31.") or ($version | str starts-with "32.")
  }

  def is-v32 [version: string]: nothing -> bool {
    ($version | str starts-with "32.")
  }

  export def all-clusters []: nothing -> list<record> {
    (all-mcs
      | where {|it| $it.pipeline in ["stable" "stable-testing" "testing"]}
      | select codename customer
      | each {|it| clusters $it.codename $it.customer}
      | flatten
      | sort-by version)
  }

  export def all-mcs []: nothing -> list<record> {
    (gs mcs capa) ++ (gs mcs capz) ++ (gs mcs capv) ++ (gs mcs capvcd)
  }
}
