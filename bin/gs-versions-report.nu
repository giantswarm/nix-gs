#!/usr/bin/env nu

source ../lib/scripts/gs.nu

use gs all-clusters

def main [] {
  let items = all-clusters

  let capa = provider-info $items "capa"
  let capz = provider-info $items "capz"
  let capv = provider-info $items "capv"
  let capvcd = provider-info $items "capvcd"

  let data = {
    items: $items,
    capa: $capa,
    capz: $capz,
    capv: $capv,
    capvcd: $capvcd,
  }

  print-versions-report "v29" $data {|it| $it.v29}
  print-versions-report "v30" $data {|it| $it.v30}
  print-versions-report "v31" $data {|it| $it.v31}
}

def provider-info [all: list<record>, provider: string]: nothing -> record {
  let items = ($all | where {|it| $it.provider == $provider})
  let total = $items | length

  {
    items: $items,
    total: $total,
    v29: (provider-stats $items {|it| $it.v29}),
    v30: (provider-stats $items {|it| $it.v30}),
    v31: (provider-stats $items {|it| $it.v31}),
  }
}

def provider-stats [items: list<record>, f: closure]: nothing -> record {
  let total = $items | length
  let count = $items | where $f | length
  let percentage = if $total != 0 {
    ($count / $total * 100)
  } else {
    0
  }

  {
    count: $count,
    percentage: $percentage,
    percentageStr: ($percentage | into string --decimals 2),
  }
}

def print-versions-report [versionStr: string, data: record, f: closure] {
  let total = $data.items | length
  let count = $data.items | where $f | length

  let capa = do $f $data.capa
  let capz = do $f $data.capz
  let capv = do $f $data.capv
  let capvcd = do $f $data.capvcd

  let separator = "---------------------------------------------------------------------------------------------";

  print $separator
  print $"(ansi green_bold)($versionStr) or newer:(ansi reset)"
  print $separator
  print $"(ansi default_bold)All providers(ansi reset): ($count) of ($total) -> (ansi default_bold)($count / $total * 100 | into string --decimals 2)%(ansi reset)"
  print $"(ansi default_bold)CAPA(ansi reset): ($capa.count) of ($data.capa.total) -> (ansi default_bold)($capa.percentageStr)%(ansi reset)"
  print $"(ansi default_bold)CAPZ(ansi reset): ($capz.count) of ($data.capz.total) -> (ansi default_bold)($capz.percentageStr)%(ansi reset)"
  print $"(ansi default_bold)CAPV(ansi reset): ($capv.count) of ($data.capv.total) -> (ansi default_bold)($capv.percentageStr)%(ansi reset)"
  print $"(ansi default_bold)CAPVCD(ansi reset): ($capvcd.count) of ($data.capvcd.total) -> (ansi default_bold)($capvcd.percentageStr)%(ansi reset)"
  print $separator
}
