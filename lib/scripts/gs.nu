module opsctl {
  # opsctl keeps a mutable clone of the installations repo under its config dir
  # and never locks it, so a second opsctl running at the same time (muster
  # starts one) can leave that clone without a valid HEAD. opsctl then aborts
  # with "Repository does not exist", which would kill a multi-minute report.
  # `--no-cache` cannot repair it -- a broken clone fails opsctl's constructor
  # before that flag is honoured -- but discarding the clone forces a fresh one.
  export def "gs mcs" [
      --provider: string = ''
      --pipeline (-p): string = ''
      --customer (-c): string = ''
    ]: nothing -> list<record> {
    let raw = try {
      list-installations $provider $pipeline $customer
    } catch {
      print $"  (ansi yellow)⚠ opsctl failed; discarding its installations clone and retrying once.(ansi reset)"
      rm --recursive --force (installations-clone)
      list-installations $provider $pipeline $customer
    }

    ($raw
      | lines
      | skip 1
      | split column --regex '\s\s+'
      | rename codename provider pipeline customer ae hostname created repository)
  }

  def list-installations [provider: string, pipeline: string, customer: string] {
    opsctl list installations --provider $provider --pipeline $pipeline --customer $customer
  }

  # Local clone of the installations repo that opsctl maintains as its cache.
  def installations-clone []: nothing -> string {
    [$env.HOME ".config" "opsctl" "github.com" "giantswarm" "installations"] | path join
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
      # An MC can be listed by opsctl yet unknown to Teleport (e.g. not yet
      # registered). Skip it rather than aborting the report -- and never
      # fall through to kubectl, which would still target the previous MC's
      # context and cache that MC's clusters under this name.
      try {
        tsh kube login $mc
      } catch {
        print $"  (ansi yellow)⚠ tsh login to ($mc) failed; skipping.(ansi reset)"
        return []
      }

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

  # One unfiltered opsctl call already covers every provider, so filter here
  # instead of invoking opsctl once per provider: same set of MCs, a quarter of
  # the work, and a quarter of the chances of tripping over opsctl's unlocked
  # installations clone. Note the provider names are opsctl's, not the cluster-app
  # ones used elsewhere in this module ("vsphere"/"cloud-director", not
  # "capv"/"capvcd"), and matching is exact so "capa-test" stays excluded.
  export def all-mcs []: nothing -> list<record> {
    gs mcs | where provider in ["capa" "capz" "vsphere" "cloud-director"]
  }
}
