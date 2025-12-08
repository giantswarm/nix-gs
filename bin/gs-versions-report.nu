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

  let versions = [32 33 34]
  for version in $versions {
    print-versions-report $version $data
  }
}

def provider-info [all: list<record>, provider: string]: nothing -> record {
  let items = ($all | where {|it| $it.provider == $provider})
  let total = $items | length

  {
    items: $items,
    total: $total,
  }
}

def provider-stats [items: list<record>, min_version: int]: nothing -> record {
  let total = $items | length
  let count = $items | where {|it| $it.major_version >= $min_version} | length
  let percentage = if $total != 0 { ($count / $total * 100) } else { 0 }

  {
    count: $count,
    percentage: $percentage,
    percentageStr: ($percentage | into string --decimals 2),
  }
}

def print-versions-report [version: int, data: record] {
  let versionStr = $"v($version)"
  let total = $data.items | length
  let count = $data.items | where major_version >= $version | length

  let capa = provider-stats $data.capa.items $version
  let capz = provider-stats $data.capz.items $version
  let capv = provider-stats $data.capv.items $version
  let capvcd = provider-stats $data.capvcd.items $version

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
