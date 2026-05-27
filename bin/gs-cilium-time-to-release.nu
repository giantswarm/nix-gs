#!/usr/bin/env nu

# Cilium time-to-release dataset generator.
#
# Emits data/cilium-times.json with one row per (cilium-version, provider) tuple,
# capturing the lead time from upstream Cilium release -> cilium-app integration ->
# Giant Swarm release PR creation -> merge to main, plus precomputed deltas.
#
# Cache layout: ~/.cache/gs-cilium-time-to-release/<YYYY-MM-DD>/
#   cilium-releases.json       upstream cilium releases (paginated)
#   cilium-app-releases.json   cilium-app releases (paginated)
#   cilium-app/                cilium-app git clone
#   releases/                  giantswarm/releases git clone
#   pr-cache.json              PR metadata, keyed by PR number
#
# Use --refresh to wipe today's cache and re-fetch.

const SCRIPT_PATH = path self
const CACHE_DIR_NAME = "gs-cilium-time-to-release"
const OUTPUT_RELATIVE = "data/cilium-times.json"
const OUTPUT_HTML_RELATIVE = "data/cilium-times.html"
const CHART_JS_VERSION = "4.5.1"
const CHART_JS_URL = "https://cdn.jsdelivr.net/npm/chart.js@4.5.1/dist/chart.umd.js"
const PROVIDERS = ["capa" "azure" "cloud-director" "eks" "proxmox" "vsphere"]
const CILIUM_UPSTREAM_API = "repos/cilium/cilium/releases"
const CILIUM_APP_API = "repos/giantswarm/cilium-app/releases"
const CILIUM_APP_URL = "https://github.com/giantswarm/cilium-app.git"
const RELEASES_URL = "https://github.com/giantswarm/releases.git"
const RELEASES_OWNER_REPO = "giantswarm/releases"
const CHART_FILE = "helm/cilium/Chart.yaml"

def main [
    --refresh (-r)  # Wipe today's cache before running
] {
    require-tool "gh"
    require-tool "git"

    let repo_root = $SCRIPT_PATH | path dirname | path dirname
    let output_path = [$repo_root $OUTPUT_RELATIVE] | path join
    let html_path = [$repo_root $OUTPUT_HTML_RELATIVE] | path join

    let cache_dir = setup-cache $refresh
    print $"(ansi cyan)Cache:(ansi reset) ($cache_dir)"

    let cilium_releases = fetch-cilium-upstream-releases $cache_dir
    print $"  cilium upstream stable releases: ($cilium_releases | length)"

    let cilium_app_dir = ensure-clone $cache_dir "cilium-app" $CILIUM_APP_URL
    let cilium_app_releases = fetch-cilium-app-releases $cache_dir
    let cilium_app_versions = build-cilium-app-version-map $cilium_app_dir $cilium_app_releases
    print $"  cilium versions integrated in cilium-app: ($cilium_app_versions | length)"

    let releases_dir = ensure-clone $cache_dir "releases" $RELEASES_URL
    let gs_releases = scan-gs-releases $releases_dir
    print $"  GS release dirs referencing cilium-app: ($gs_releases | length)"

    let pr_cache_path = [$cache_dir "pr-cache.json"] | path join
    let enriched = enrich-with-prs $gs_releases $releases_dir $pr_cache_path

    let rows = build-rows $cilium_releases $cilium_app_versions $enriched
    write-output $rows $output_path
    print $"(ansi green)Wrote ($rows | length) rows to ($output_path)(ansi reset)"

    let chartjs_src = ensure-chartjs $cache_dir
    write-html $rows $chartjs_src $html_path
    print $"(ansi green)Wrote HTML to ($html_path)(ansi reset)"
}

# Ensure a CLI tool is on PATH.
def require-tool [tool: string]: nothing -> nothing {
    if (which $tool | is-empty) {
        error make { msg: $"The '($tool)' CLI is required but was not found." }
    }
}

# Create today's cache dir, optionally wiping first.
def setup-cache [refresh: bool]: nothing -> string {
    let today = date now | format date "%Y-%m-%d"
    let cache_dir = [$env.HOME ".cache" $CACHE_DIR_NAME $today] | path join

    if $refresh and ($cache_dir | path exists) {
        rm -rf $cache_dir
    }
    if not ($cache_dir | path exists) {
        mkdir $cache_dir
    }
    $cache_dir
}

# Fetch upstream cilium releases (cached); return stable patches only.
def fetch-cilium-upstream-releases [cache_dir: string]: nothing -> list<record> {
    let path = [$cache_dir "cilium-releases.json"] | path join
    if not ($path | path exists) {
        print "Fetching cilium upstream releases..."
        gh api $"($CILIUM_UPSTREAM_API)?per_page=100" --paginate | save -f $path
    }

    open $path
        | each {|r|
            let v = normalize-version $r.tag_name
            if (is-stable-semver $v) {
                { version: $v, published_at: $r.published_at }
            } else { null }
        }
        | compact
}

# Fetch cilium-app releases (cached). Returns all (incl. pre-releases).
def fetch-cilium-app-releases [cache_dir: string]: nothing -> list<record> {
    let path = [$cache_dir "cilium-app-releases.json"] | path join
    if not ($path | path exists) {
        print "Fetching cilium-app releases..."
        gh api $"($CILIUM_APP_API)?per_page=100" --paginate | save -f $path
    }

    open $path | each {|r|
        { tag: $r.tag_name, published_at: $r.published_at }
    }
}

# Clone a repo into the cache (full clone, idempotent).
def ensure-clone [cache_dir: string, name: string, url: string]: nothing -> string {
    let repo_path = [$cache_dir $name] | path join
    if not ($repo_path | path exists) {
        print $"Cloning ($name)..."
        git clone --quiet $url $repo_path
    }
    $repo_path
}

# Fetch the pinned Chart.js UMD bundle (cached) and return its source text.
def ensure-chartjs [cache_dir: string]: nothing -> string {
    let path = [$cache_dir "chart.umd.js"] | path join
    if not ($path | path exists) {
        print $"Fetching Chart.js ($CHART_JS_VERSION)..."
        http get $CHART_JS_URL | save -f $path
    }
    open --raw $path | decode utf-8
}

# For each upstream cilium version that appears as appVersion in any cilium-app
# release tag's Chart.yaml, return:
#   cilium_version, cilium_app_version, cilium_app_released_at  (earliest tag)
#   all_app_versions: list of every cilium-app version pinning this cilium_version
def build-cilium-app-version-map [
    repo_path: string
    releases: list<record>
]: nothing -> list<record> {
    let tags = git -C $repo_path tag | lines | where {|t| not ($t | is-empty)}

    let chart_info = $tags | each {|tag|
        let res = do -i { git -C $repo_path show $"($tag):($CHART_FILE)" } | complete
        if $res.exit_code != 0 {
            null
        } else {
            let chart = try { $res.stdout | from yaml } catch { null }
            if $chart == null {
                null
            } else {
                let app_v = $chart | get -o appVersion
                let chart_v = $chart | get -o version
                if $app_v == null or $chart_v == null {
                    null
                } else {
                    {
                        tag: $tag,
                        cilium_version: (normalize-version $app_v),
                        cilium_app_version: (normalize-version $chart_v),
                    }
                }
            }
        }
    } | compact

    # Join with GitHub releases for published_at; drop tags without a release.
    let releases_by_tag = $releases | reduce -f {} {|r, acc|
        $acc | upsert $r.tag $r
    }

    let with_dates = $chart_info | each {|x|
        let rel = $releases_by_tag | get -o $x.tag
        if $rel == null {
            null
        } else {
            $x | merge { cilium_app_released_at: $rel.published_at }
        }
    } | compact

    # Only stable cilium versions.
    let stable = $with_dates | where {|x| is-stable-semver $x.cilium_version}

    # Group by upstream cilium version; record earliest cilium-app integration
    # plus the full set of cilium-app versions that pin this cilium version.
    $stable
        | group-by cilium_version
        | transpose cilium_version entries
        | each {|g|
            let earliest = $g.entries | sort-by cilium_app_released_at | first
            {
                cilium_version: $g.cilium_version,
                cilium_app_version: $earliest.cilium_app_version,
                cilium_app_tag: $earliest.tag,
                cilium_app_released_at: $earliest.cilium_app_released_at,
                all_app_versions: ($g.entries | get cilium_app_version | uniq),
            }
        }
}

# Scan all <provider>/v*/release.yaml (incl. archived/) for cilium app entries.
def scan-gs-releases [repo_path: string]: nothing -> list<record> {
    $PROVIDERS | each {|provider|
        let provider_dir = [$repo_path $provider] | path join
        if not ($provider_dir | path exists) {
            []
        } else {
            collect-release-dirs $provider_dir | each {|dir|
                parse-release-yaml $repo_path $provider $dir
            } | compact
        }
    } | flatten
}

# All immediate release dirs under <provider_dir>, plus those under archived/.
def collect-release-dirs [provider_dir: string]: nothing -> list<string> {
    let direct = ls $provider_dir
        | where type == "dir"
        | get name
        | where {|n| ($n | path basename) != "archived"}

    let archived_dir = [$provider_dir "archived"] | path join
    let archived = if ($archived_dir | path exists) {
        ls $archived_dir | where type == "dir" | get name
    } else { [] }

    $direct ++ $archived
}

# Read one release.yaml; return record if it has a cilium app entry, else null.
def parse-release-yaml [
    repo_path: string
    provider: string
    dir: string
]: nothing -> record {
    let release_yaml = [$dir "release.yaml"] | path join
    if not ($release_yaml | path exists) {
        return null
    }
    let parsed = try { open $release_yaml } catch { null }
    if $parsed == null {
        return null
    }
    let apps = $parsed | get -o spec | default {} | get -o apps | default []
    let cilium_entry = $apps | where name == "cilium" | get -o 0
    if $cilium_entry == null {
        return null
    }
    let rel_path = $release_yaml | str replace $"($repo_path)/" ""
    # A release that has been archived now lives at <provider>/archived/v<X>/,
    # but its release-PR add-commit is on the original <provider>/v<X>/ path.
    # Search both candidate paths so we attribute the lead-time metric to the
    # release PR rather than the archive PR.
    let alt_paths = if ($rel_path | str contains "/archived/") {
        [($rel_path | str replace "/archived/" "/")]
    } else { [] }

    {
        provider: $provider,
        release_version: ($dir | path basename | str replace -r '^v' ''),
        cilium_app_version: (normalize-version $cilium_entry.version),
        release_yaml_path: $rel_path,
        candidate_paths: ([$rel_path] ++ $alt_paths),
    }
}

# For each GS release entry, find the commit that ADDED the release.yaml on
# main and (if a PR # is in the message or the commits/pulls API) the PR's
# created_at / merged_at. PR data is cached on disk in pr-cache.json.
def enrich-with-prs [
    gs_releases: list<record>
    releases_dir: string
    pr_cache_path: string
]: nothing -> list<record> {
    # Step 1: find adding commit + PR number for each release.
    let with_commits = $gs_releases | each {|r|
        let info = find-adding-commit $releases_dir $r.candidate_paths
        if $info == null {
            $r | merge { sha: null, commit_date: null, pr_number: null }
        } else {
            $r | merge $info
        }
    }

    # Step 2: for commits without a PR # in the message, query the API once.
    let with_pr_nums = $with_commits | each {|r|
        if $r.pr_number != null or $r.sha == null {
            $r
        } else {
            let pr = lookup-pr-for-commit $r.sha
            $r | upsert pr_number $pr
        }
    }

    # Step 3: fetch PR metadata for each unique PR number, with on-disk cache.
    let pr_numbers = $with_pr_nums
        | get pr_number
        | where {|x| $x != null}
        | uniq

    mut pr_cache = if ($pr_cache_path | path exists) {
        open $pr_cache_path
    } else { {} }

    let total = $pr_numbers | length
    mut fetched = 0
    for pr_num in $pr_numbers {
        let key = $pr_num | into string
        if ($pr_cache | get -o $key) == null {
            $fetched = $fetched + 1
            print $"  fetching PR ($pr_num) ... \(($fetched)/($total)\)"
            let res = do -i { gh api $"repos/($RELEASES_OWNER_REPO)/pulls/($pr_num)" } | complete
            if $res.exit_code == 0 {
                let pr_data = $res.stdout | from json
                $pr_cache = $pr_cache | upsert $key {
                    created_at: $pr_data.created_at,
                    merged_at: $pr_data.merged_at,
                }
            } else {
                $pr_cache = $pr_cache | upsert $key { created_at: null, merged_at: null }
            }
        }
    }

    $pr_cache | to json --indent 2 | save -f $pr_cache_path

    # Step 4: attach PR dates to each release. Fall back to commit_date for
    # merged_at when the PR query failed (e.g. release added by direct push).
    let prs = $pr_cache
    $with_pr_nums | each {|r|
        let pr = if $r.pr_number == null {
            null
        } else {
            $prs | get -o ($r.pr_number | into string)
        }

        let created_at = if $pr == null { null } else { $pr.created_at }
        let merged_at = if $pr == null or $pr.merged_at == null {
            $r.commit_date
        } else { $pr.merged_at }

        $r | merge {
            gs_release_pr_created_at: $created_at,
            gs_release_pr_merged_at: $merged_at,
        }
    }
}

# Find the earliest commit across one or more candidate paths that ADDED the
# file. Used to handle archived releases: <provider>/archived/v<X>/release.yaml
# was "added" by the archive PR, but the actual release PR is on the original
# <provider>/v<X>/release.yaml path. Returns {sha, commit_date, pr_number}.
def find-adding-commit [repo_path: string, candidate_paths: list<string>]: nothing -> record {
    let results = $candidate_paths | each {|p|
        let res = do -i {
            git -C $repo_path log --diff-filter=A --max-count=1 --format='%H|%aI|%s' -- $p
        } | complete
        let line = $res.stdout | str trim
        if $res.exit_code != 0 or ($line | is-empty) {
            null
        } else {
            let parts = $line | split row "|"
            if ($parts | length) < 3 {
                null
            } else {
                let subject = $parts | skip 2 | str join "|"
                let pr_match = $subject | parse --regex '\(#(?P<pr>\d+)\)' | get -o pr | get -o 0
                {
                    sha: ($parts | get 0),
                    commit_date: ($parts | get 1),
                    pr_number: (if $pr_match == null { null } else { $pr_match | into int }),
                }
            }
        }
    } | compact

    if ($results | is-empty) {
        null
    } else {
        $results | sort-by commit_date | first
    }
}

# Fallback: ask GitHub which PR a commit belongs to.
def lookup-pr-for-commit [sha: string]: nothing -> int {
    let res = do -i { gh api $"repos/($RELEASES_OWNER_REPO)/commits/($sha)/pulls" } | complete
    if $res.exit_code != 0 {
        return null
    }
    let prs = try { $res.stdout | from json } catch { [] }
    if ($prs | is-empty) {
        null
    } else {
        $prs | get 0 | get number
    }
}

# Join everything into the final dataset. One row per (cilium-version, provider),
# plus a single null-provider row for cilium versions integrated in cilium-app
# but not yet shipped in any GS release.
def build-rows [
    cilium_releases: list<record>
    cilium_app_versions: list<record>
    enriched: list<record>
]: nothing -> list<record> {
    let cilium_by_version = $cilium_releases | reduce -f {} {|r, acc|
        $acc | upsert $r.version $r
    }

    let rows = $cilium_app_versions | each {|cav|
        let cilium_release = $cilium_by_version | get -o $cav.cilium_version
        let cilium_released_at = if $cilium_release == null { null } else { $cilium_release.published_at }

        let matching = $enriched | where {|e| $e.cilium_app_version in $cav.all_app_versions}

        if ($matching | is-empty) {
            [{
                cilium_version: $cav.cilium_version,
                cilium_released_at: $cilium_released_at,
                cilium_app_version: $cav.cilium_app_version,
                cilium_app_released_at: $cav.cilium_app_released_at,
                provider: null,
                gs_cilium_app_version: null,
                gs_release_version: null,
                gs_release_pr_number: null,
                gs_release_pr_created_at: null,
                gs_release_pr_merged_at: null,
            }]
        } else {
            $matching
                | group-by provider
                | transpose provider items
                | each {|g|
                    let earliest = earliest-by-merge $g.items
                    {
                        cilium_version: $cav.cilium_version,
                        cilium_released_at: $cilium_released_at,
                        cilium_app_version: $cav.cilium_app_version,
                        cilium_app_released_at: $cav.cilium_app_released_at,
                        provider: $g.provider,
                        gs_cilium_app_version: $earliest.cilium_app_version,
                        gs_release_version: $earliest.release_version,
                        gs_release_pr_number: $earliest.pr_number,
                        gs_release_pr_created_at: $earliest.gs_release_pr_created_at,
                        gs_release_pr_merged_at: $earliest.gs_release_pr_merged_at,
                    }
                }
        }
    } | flatten

    $rows | each {|row|
        $row | merge {
            days_cilium_to_app: (days-between $row.cilium_released_at $row.cilium_app_released_at),
            days_app_to_gs_pr: (days-between $row.cilium_app_released_at $row.gs_release_pr_created_at),
            days_gs_pr_review: (days-between $row.gs_release_pr_created_at $row.gs_release_pr_merged_at),
            days_cilium_to_gs_merge: (days-between $row.cilium_released_at $row.gs_release_pr_merged_at),
        }
    } | sort-by cilium_released_at provider gs_release_version
}

# Pick the GS release that merged earliest. Falls back to the lowest version
# string if no merge dates are known.
def earliest-by-merge [items: list<record>]: nothing -> record {
    let with_dates = $items | where {|x| $x.gs_release_pr_merged_at != null}
    if ($with_dates | is-empty) {
        $items | sort-by release_version | first
    } else {
        $with_dates | sort-by gs_release_pr_merged_at | first
    }
}

# Difference in days between two ISO 8601 timestamps, or null if either is null.
def days-between [from: any, to: any]: nothing -> any {
    if $from == null or $to == null {
        return null
    }
    let diff = ($to | into datetime) - ($from | into datetime)
    $diff / 1day
}

# Strip a leading "v" from a version string and trim whitespace.
def normalize-version [v: any]: nothing -> string {
    $v | into string | str trim | str replace -r '^v' ''
}

# True if "X.Y.Z" with digits only (stable, not a pre-release).
def is-stable-semver [version: string]: nothing -> bool {
    $version =~ '^\d+\.\d+\.\d+$'
}

# Write the dataset to disk, creating the parent directory if needed.
def write-output [rows: list<record>, output_path: string]: nothing -> nothing {
    let dir = $output_path | path dirname
    if not ($dir | path exists) {
        mkdir $dir
    }
    $rows | to json --indent 2 | save -f $output_path
}

# Static HTML/CSS/JS template. Placeholders __CHARTJS_SRC__, __DATA_JSON__ and
# __GENERATED_AT__ are substituted (literally) at write time.
const HTML_TEMPLATE = r##'<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cilium time-to-release</title>
<style>
  :root { --fg:#1d1d1f; --muted:#6e6e73; --border:#e0e0e0; --bg:#ffffff; }
  * { box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: var(--fg); margin: 0; padding: 24px; background: var(--bg); }
  h1 { font-size: 20px; margin: 0 0 4px; }
  .sub { color: var(--muted); font-size: 13px; line-height: 1.5; margin: 0 0 16px; max-width: 70ch; }
  .panel { display: flex; flex-wrap: wrap; gap: 12px; margin-bottom: 16px; }
  .card { border: 1px solid var(--border); border-radius: 8px; padding: 10px 12px; min-width: 140px; }
  .card .name { font-size: 12px; color: var(--muted); text-transform: uppercase; letter-spacing: .04em; }
  .card .big { font-size: 18px; font-weight: 600; }
  .card .small { font-size: 12px; color: var(--muted); }
  .filters { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; margin-bottom: 12px; }
  .filters .lbl { font-size: 13px; color: var(--muted); margin-right: 4px; }
  button.f { border: 1px solid var(--border); background: #fff; color: var(--fg); border-radius: 999px; padding: 4px 12px; font-size: 13px; cursor: pointer; }
  button.f.off { opacity: .4; text-decoration: line-through; }
  button.f.reset { border-style: dashed; }
  .chart-wrap { position: relative; width: 100%; }
  footer { color: var(--muted); font-size: 12px; margin-top: 16px; }
</style>
</head>
<body>
<h1>Cilium time-to-release</h1>
<p class="sub">Lead time from an upstream Cilium release to each Giant Swarm provider, split into phases:
  <strong>upstream &rarr; cilium-app</strong>, <strong>cilium-app &rarr; GS release PR</strong>, <strong>GS PR review</strong>.
  Hover a bar for details; click a segment to open its release/PR. Generated __GENERATED_AT__.</p>

<div class="panel" id="stats"></div>
<div class="filters" id="filters"><span class="lbl">Providers:</span></div>
<div class="chart-wrap"><canvas id="chart"></canvas></div>
<footer>One row per (cilium&nbsp;version, provider). Grey rows never shipped in a GS release.</footer>

<script>__CHARTJS_SRC__</script>
<script>
const DATA = __DATA_JSON__;

const PHASES = [
  { key: 'days_cilium_to_app', label: 'upstream → cilium-app', color: '#4e79a7' },
  { key: 'days_app_to_gs_pr',  label: 'cilium-app → GS PR',    color: '#f28e2b' },
  { key: 'days_gs_pr_review',  label: 'GS PR review',              color: '#59a14f' },
];
const STALLED_COLOR = '#bab0ac';

const isStalled = r => r.provider === null;
const rowKey = r => isStalled(r) ? '__stalled__' : r.provider;
const fmtDays = v => (v === null || v === undefined) ? '—' : (Math.round(v * 10) / 10) + ' d';
const fmtDate = s => s ? s.slice(0, 10) : '—';

function median(xs) {
  if (!xs.length) return null;
  const s = [...xs].sort((a, b) => a - b);
  const m = Math.floor(s.length / 2);
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
}
function mean(xs) { return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null; }

function cmp(a, b) {
  const da = a.cilium_released_at, db = b.cilium_released_at;
  if (da !== db) {
    if (!da) return 1;
    if (!db) return -1;
    return da < db ? 1 : -1;
  }
  if (a.cilium_version !== b.cilium_version) return a.cilium_version < b.cilium_version ? 1 : -1;
  const pa = a.provider || '~', pb = b.provider || '~';
  return pa < pb ? -1 : pa > pb ? 1 : 0;
}

function urlForSegment(r, seg) {
  if (seg === 0) return 'https://github.com/cilium/cilium/releases/tag/v' + r.cilium_version;
  if (seg === 1) return 'https://github.com/giantswarm/cilium-app/releases/tag/v' + r.cilium_app_version;
  if (seg === 2) {
    if (r.gs_release_pr_number != null) return 'https://github.com/giantswarm/releases/pull/' + r.gs_release_pr_number;
    if (r.provider && r.gs_release_version) return 'https://github.com/giantswarm/releases/tree/main/' + r.provider + '/v' + r.gs_release_version;
  }
  return null;
}

const providers = [...new Set(DATA.filter(r => !isStalled(r)).map(r => r.provider))].sort();
const hasStalled = DATA.some(isStalled);
const filterKeys = hasStalled ? [...providers, '__stalled__'] : [...providers];
const activeKeys = new Set(filterKeys);

function renderStats() {
  const el = document.getElementById('stats');
  el.innerHTML = '';
  providers.forEach(p => {
    const totals = DATA.filter(r => r.provider === p && r.days_cilium_to_gs_merge != null).map(r => r.days_cilium_to_gs_merge);
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML =
      '<div class="name">' + p + '</div>' +
      '<div class="big">' + fmtDays(median(totals)) + '</div>' +
      '<div class="small">median &middot; mean ' + fmtDays(mean(totals)) + ' &middot; ' + totals.length + ' shipped</div>';
    el.appendChild(card);
  });
  const card = document.createElement('div');
  card.className = 'card';
  card.innerHTML = '<div class="name">stalled</div><div class="big">' + DATA.filter(isStalled).length + '</div><div class="small">never shipped</div>';
  el.appendChild(card);
}

function renderFilters() {
  const el = document.getElementById('filters');
  filterKeys.forEach(k => {
    const btn = document.createElement('button');
    btn.className = 'f';
    btn.textContent = k === '__stalled__' ? 'not shipped' : k;
    btn.onclick = () => {
      if (activeKeys.has(k)) activeKeys.delete(k); else activeKeys.add(k);
      btn.classList.toggle('off', !activeKeys.has(k));
      render();
    };
    el.appendChild(btn);
  });
  const reset = document.createElement('button');
  reset.className = 'f reset';
  reset.textContent = 'all';
  reset.onclick = () => {
    filterKeys.forEach(k => activeKeys.add(k));
    el.querySelectorAll('button.f').forEach(b => b.classList.remove('off'));
    render();
  };
  el.appendChild(reset);
}

const wrap = document.querySelector('.chart-wrap');
const ctx = document.getElementById('chart');
let chart;
let currentRows = [];

const groupBands = {
  id: 'groupBands',
  beforeDatasetsDraw(c) {
    const y = c.scales.y, area = c.chartArea, g = c.ctx;
    if (!y || !currentRows.length) return;
    const step = currentRows.length > 1 ? Math.abs(y.getPixelForValue(1) - y.getPixelForValue(0)) : (area.bottom - area.top);
    const half = step / 2;
    g.save();
    let parity = 0, last = null;
    for (let i = 0; i < currentRows.length; i++) {
      const v = currentRows[i].cilium_version;
      if (v !== last) { parity ^= 1; last = v; }
      if (!parity) continue;
      const center = y.getPixelForValue(i);
      g.fillStyle = 'rgba(0,0,0,0.035)';
      g.fillRect(area.left, center - half, area.right - area.left, step);
    }
    g.restore();
  }
};

function render() {
  currentRows = DATA.filter(r => activeKeys.has(rowKey(r))).sort(cmp);
  const labels = currentRows.map(r => r.cilium_version + '  ·  ' + (r.provider || '(not shipped)'));
  const datasets = PHASES.map((ph, i) => ({
    label: ph.label,
    data: currentRows.map(r => r[ph.key]),
    backgroundColor: currentRows.map(r => (isStalled(r) && i === 0) ? STALLED_COLOR : ph.color),
    borderWidth: 0,
  }));
  wrap.style.height = (currentRows.length * 28 + 90) + 'px';
  if (chart) {
    chart.data.labels = labels;
    chart.data.datasets = datasets;
    chart.update();
    return;
  }
  chart = new Chart(ctx, {
    type: 'bar',
    data: { labels, datasets },
    options: {
      indexAxis: 'y',
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', axis: 'y', intersect: false },
      scales: {
        x: { stacked: true, beginAtZero: true, title: { display: true, text: 'days' } },
        y: { stacked: true, ticks: { autoSkip: false, font: { size: 11 } } },
      },
      plugins: {
        legend: { position: 'top' },
        tooltip: {
          callbacks: {
            title: items => {
              const r = currentRows[items[0].dataIndex];
              return r.cilium_version + '  ·  ' + (r.provider || '(not shipped)');
            },
            label: item => PHASES[item.datasetIndex].label + ': ' + fmtDays(item.parsed.x),
            afterBody: items => {
              const r = currentRows[items[0].dataIndex];
              const L = [''];
              L.push('cilium ' + r.cilium_version + ' released ' + fmtDate(r.cilium_released_at));
              L.push('cilium-app ' + r.cilium_app_version + ' released ' + fmtDate(r.cilium_app_released_at));
              if (r.provider) {
                L.push('GS ' + r.provider + ' ' + r.gs_release_version);
                L.push('PR created ' + fmtDate(r.gs_release_pr_created_at));
                L.push('PR merged ' + fmtDate(r.gs_release_pr_merged_at));
                if (r.days_cilium_to_gs_merge != null) L.push('total lead time ' + fmtDays(r.days_cilium_to_gs_merge));
              } else {
                L.push('(never shipped in a GS release)');
              }
              L.push('');
              L.push('click a segment to open its release/PR');
              return L;
            },
          }
        }
      },
      onHover: (evt, els) => { ctx.style.cursor = els.length ? 'pointer' : 'default'; },
      onClick: evt => {
        const pts = chart.getElementsAtEventForMode(evt, 'nearest', { intersect: true }, true);
        if (!pts.length) return;
        const r = currentRows[pts[0].index];
        const url = urlForSegment(r, pts[0].datasetIndex);
        if (url) window.open(url, '_blank');
      },
    },
    plugins: [groupBands],
  });
}

renderStats();
renderFilters();
render();
</script>
</body>
</html>
'##

# Render a self-contained interactive HTML view of the dataset. Chart.js source
# and the dataset are inlined so the file works offline and via file://.
def write-html [
    rows: list<record>
    chartjs_src: string
    output_path: string
]: nothing -> nothing {
    let generated_at = date now | format date "%Y-%m-%d %H:%M %Z"
    let data_json = $rows | to json

    let html = $HTML_TEMPLATE
        | str replace "__CHARTJS_SRC__" $chartjs_src
        | str replace "__DATA_JSON__" $data_json
        | str replace "__GENERATED_AT__" $generated_at

    let dir = $output_path | path dirname
    if not ($dir | path exists) {
        mkdir $dir
    }
    $html | save -f $output_path
}
