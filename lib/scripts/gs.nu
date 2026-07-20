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
    let cacheDir = [$env.HOME ".cache" "gs-clusters" (date now | format date "%Y-%m-%d")] | path join
    if not ($cacheDir | path exists) {
      mkdir $cacheDir
    }

    let clustersFile = [$cacheDir $"($mc)_clusters.json"] | path join

    # A previous run may have written a 0-byte file when the fetch failed
    # (e.g. a login or connectivity issue). Treat such a file as an invalid
    # cache and re-fetch, otherwise `open` yields nothing and `get items`
    # crashes with "nothing doesn't support cell paths".
    if not (cache-valid $clustersFile) {
      do -c { tsh kube login $mc }

      # `kubectl` can exit non-zero (e.g. an API server timeout), which would
      # abort the whole block here. Swallow the error with `try` so we can
      # inspect the result and skip this MC gracefully instead.
      try {
        kubectl get clusters.cluster.x-k8s.io -A --output json out> $clustersFile
      }

      # If the fetch produced no usable data, remove the poisoned cache file
      # so it is retried on the next run, and skip this MC instead of
      # aborting the whole report.
      if not (cache-valid $clustersFile) {
        print $"  (ansi yellow)⚠ No cluster data for ($mc); skipping.(ansi reset)"
        rm --force $clustersFile
        return []
      }
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
      | each {|it| $it | insert major_version (extract-major-version $it.version)}
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

  def extract-major-version [version: string]: nothing -> int {
    if $version == "unknown" {
      error make {msg: "Cannot extract major version from unknown version"}
    } else {
      try {
        ($version | split row "." | get 0 | into int)
      } catch {
        error make {msg: $"Cannot parse major version from: ($version)"}
      }
    }
  }

  # Returns true when the cache file exists and is non-empty. A 0-byte file
  # indicates a failed fetch and must be treated as an invalid cache.
  def cache-valid [file: string]: nothing -> bool {
    ($file | path exists) and ((ls $file | get 0.size) > 0B)
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
