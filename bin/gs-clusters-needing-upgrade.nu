#!/usr/bin/env nu

# List the clusters running a release older than the one that ships a fix.
#
# Pass the first fixed release of each major line, e.g. for Flatcar 4757.2.2:
#
#   ./gs-clusters-needing-upgrade.nu 35.3.0 36.2.0
#
# A cluster needs an upgrade when it is below the fixed release of its major,
# or when its major has no fixed release and is older than the newest one
# given. Majors newer than every fixed release are assumed to include the fix.

source ../lib/scripts/gs.nu

use gs all-clusters

def main [
    ...fixed: string  # First fixed release of each major, e.g. 35.3.0 36.2.0
    --by-customer     # Summarise per customer instead of listing clusters
  ] {
  if ($fixed | is-empty) {
    error make {msg: "Pass at least one fixed release, e.g. 35.3.0 36.2.0"}
  }

  let fixed_by_major = ($fixed
    | each {|it| {major: (parse-version $it).0, version: $it} }
    | sort-by major)

  let items = (all-clusters
    | where {|it| needs-upgrade $it.version $fixed_by_major }
    | each {|it| $it | insert upgrade_to (upgrade-target $it.version $fixed_by_major) }
    | select customer mc provider name version upgrade_to
    | sort-by customer mc name)

  if $by_customer {
    summarise-by-customer $items
  } else {
    $items
  }
}

def summarise-by-customer [items: list<record>]: nothing -> list<record> {
  ($items
    | group-by customer
    | transpose customer data
    | each {|it|
        {
          customer: $it.customer,
          count: ($it.data | length),
          mcs: ($it.data | get mc | uniq | sort | str join ", "),
          versions: ($it.data | get version | uniq | sort | str join ", "),
        }
      }
    | sort-by customer)
}

# An "unknown" version cannot be proven fixed, so it is reported.
def needs-upgrade [version: string, fixed_by_major: list<record>]: nothing -> bool {
  if $version == "unknown" {
    return true
  }

  let current = parse-version $version
  let fixed = $fixed_by_major | where major == $current.0
  if ($fixed | is-empty) {
    $current.0 < ($fixed_by_major | last | get major)
  } else {
    version-less $current (parse-version ($fixed | first | get version))
  }
}

# Same major's fix when there is one, otherwise every fixed release newer than
# the cluster's major (a major upgrade is needed).
def upgrade-target [version: string, fixed_by_major: list<record>]: nothing -> string {
  if $version == "unknown" {
    return ($fixed_by_major | get version | str join " / ")
  }

  let major = (parse-version $version).0
  let same_major = $fixed_by_major | where major == $major
  if ($same_major | is-empty) {
    $fixed_by_major | where major > $major | get version | str join " / "
  } else {
    $same_major | first | get version
  }
}

# Pre-release suffixes (e.g. "36.2.1-t.abc") are dropped: the base version
# already ships everything its release line does.
def parse-version [version: string]: nothing -> list<int> {
  try {
    $version | split row "-" | first | split row "." | each {|it| $it | into int }
  } catch {
    error make {msg: $"Cannot parse version: ($version)"}
  }
}

def version-less [a: list<int>, b: list<int>]: nothing -> bool {
  for index in 0..2 {
    if ($a | get $index) != ($b | get $index) {
      return (($a | get $index) < ($b | get $index))
    }
  }
  false
}
