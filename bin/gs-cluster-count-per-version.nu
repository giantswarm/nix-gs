#!/usr/bin/env nu

source ../lib/scripts/gs.nu

use gs [clusters, all-clusters]

def main [
    --mc: string  # MC name to list clusters for
  ] {


  let items = if ($mc | is-empty) {
    all-clusters
  } else {
    clusters $mc
  }

  ($items
    | group-by version
    | transpose
    | rename version data
    | each {|it| $it | insert count ($it.data | length) | insert mcs ($it.data | get mc | sort | uniq | str join ", ") }
    | select version count mcs
    | sort-by version
  )
}
