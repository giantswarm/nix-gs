#!/usr/bin/env nu

# Nix package updater script
# Updates packages by fetching latest versions from GitHub and computing Nix hashes
#
# JSON Schema:
#   Common fields (required):
#     - version: string      Current package version
#     - sourceType: string   "github" or "git"
#     - vendorHash: string   Nix hash for Go vendor dependencies
#
#   GitHub source (sourceType: "github"):
#     - owner: string        GitHub repository owner
#     - repo: string         GitHub repository name
#     - hash: string         Nix hash for source tarball
#
#   Git source (sourceType: "git"):
#     - url: string          Git repository URL
#     - rev: string          Git revision (commit hash)
#
#   Optional:
#     - tagPrefix: string    Version tag prefix (default: "v")

# Paths
const SCRIPT_PATH = path self
const PACKAGES_DIR = "lib/packages"
const JSON_EXT = ".json"

# Source types
const SOURCE_TYPE_GIT = "git"
const SOURCE_TYPE_GITHUB = "github"

# Git patterns
const DEFAULT_TAG_PREFIX = "v"
const GIT_TAG_REF_PATTERN = "\trefs/tags/"

# Nix build
const FLAKE_PKG_PREFIX = ".#"
const HASH_PATTERN = "got:"
const HASH_REGEX = 'got:\s+(sha256-[A-Za-z0-9+/=]+)'

# Output
const ERROR_PREVIEW_LENGTH = 500

# Validation
const REQUIRED_FIELDS = ["version", "sourceType", "vendorHash"]
const GITHUB_REQUIRED_FIELDS = ["owner", "repo", "hash"]
const GIT_REQUIRED_FIELDS = ["url", "rev"]

# Main entry point
def main [
    ...packages: string  # Package names to update (omit for all)
    --dry-run (-n)       # Show what would be updated without making changes
    --list (-l)          # List available packages
]: nothing -> nothing {
    let packages_path = get-packages-path

    if $list {
        list-packages $packages_path
        return
    }

    let pkg_names = if ($packages | is-empty) {
        get-all-package-names $packages_path
    } else {
        $packages
    }

    update-packages $pkg_names $packages_path $dry_run
}

# Get path to packages directory
def get-packages-path []: nothing -> string {
    let repo_root = $SCRIPT_PATH | path dirname | path dirname

    [$repo_root $PACKAGES_DIR] | path join
}

# List available packages
def list-packages [packages_path: string]: nothing -> nothing {
    let packages = get-all-package-names $packages_path

    print "Available packages:"
    for name in $packages {
        let json_path = [$packages_path $"($name)($JSON_EXT)"] | path join
        let meta = load-package-json $json_path
        print $"  ($name) (($meta.version)) - ($meta.sourceType)"
    }
}

# Get all package names from JSON files
def get-all-package-names [packages_path: string]: nothing -> list<string> {
    glob $"($packages_path)/*($JSON_EXT)"
        | each { path basename | str replace $JSON_EXT "" }
        | sort
}

# Update multiple packages
def update-packages [
    pkg_names: list<string>
    packages_path: string
    dry_run: bool
]: nothing -> nothing {
    require-gh

    let results = $pkg_names | each {|name|
        update-package $name $packages_path $dry_run
    }

    print-summary $results
}

# Ensure gh CLI is available
def require-gh []: nothing -> nothing {
    if (which gh | is-empty) {
        error make {
            msg: "The 'gh' CLI is required but was not found. Install it from https://cli.github.com/"
        }
    }
}

# Update a single package
def update-package [
    name: string
    packages_path: string
    dry_run: bool
]: nothing -> record {
    let json_path = [$packages_path $"($name)($JSON_EXT)"] | path join

    if not ($json_path | path exists) {
        print $"(ansi red)Error:(ansi reset) Package '($name)' not found"
        return { name: $name, status: "not_found", from: null, to: null }
    }

    print $"(ansi cyan)Updating ($name)...(ansi reset)"

    let meta = load-package-json $json_path
    let latest = fetch-latest-version $meta

    if $latest.version == $meta.version {
        print $"  Already at latest version: ($meta.version)"
        return { name: $name, status: "up_to_date", from: $meta.version, to: $meta.version }
    }

    print $"  Current: ($meta.version) → Latest: ($latest.version)"

    if $dry_run {
        print $"  (ansi yellow)Dry run: skipping update(ansi reset)"
        return { name: $name, status: "would_update", from: $meta.version, to: $latest.version }
    }

    let updated_meta = compute-and-update-hashes $meta $latest $json_path $name

    print $"  (ansi green)Updated ($json_path)(ansi reset)"
    { name: $name, status: "updated", from: $meta.version, to: $latest.version }
}

# Print summary of update results
def print-summary [results: list<record>]: nothing -> nothing {
    let updated = $results | where status == "updated" | length
    let up_to_date = $results | where status == "up_to_date" | length
    let would_update = $results | where status == "would_update" | length
    let not_found = $results | where status == "not_found" | length

    print ""
    print $"(ansi cyan)Summary:(ansi reset)"

    if $updated > 0 {
        print $"  (ansi green)Updated:(ansi reset) ($updated)"
    }
    if $up_to_date > 0 {
        print $"  Up to date: ($up_to_date)"
    }
    if $would_update > 0 {
        print $"  (ansi yellow)Would update:(ansi reset) ($would_update)"
    }
    if $not_found > 0 {
        print $"  (ansi red)Not found:(ansi reset) ($not_found)"
    }
}

# Load and parse JSON metadata file with validation
def load-package-json [path: string]: nothing -> record {
    let data = open $path

    # Validate common required fields
    for field in $REQUIRED_FIELDS {
        if ($field not-in $data) {
            error make { msg: $"Missing required field '($field)' in ($path)" }
        }
    }

    # Validate source-type-specific fields
    let extra_fields = if $data.sourceType == $SOURCE_TYPE_GITHUB {
        $GITHUB_REQUIRED_FIELDS
    } else if $data.sourceType == $SOURCE_TYPE_GIT {
        $GIT_REQUIRED_FIELDS
    } else {
        error make { msg: $"Unknown sourceType '($data.sourceType)' in ($path)" }
    }

    for field in $extra_fields {
        if ($field not-in $data) {
            error make { msg: $"Missing required field '($field)' for ($data.sourceType) source in ($path)" }
        }
    }

    $data
}

# Fetch latest version from GitHub or git
def fetch-latest-version [meta: record]: nothing -> record {
    let prefix = $meta.tagPrefix? | default $DEFAULT_TAG_PREFIX
    if $meta.sourceType == $SOURCE_TYPE_GIT {
        fetch-git-latest $meta.url $prefix
    } else {
        fetch-github-latest $meta.owner $meta.repo $prefix
    }
}

# Fetch latest version via git (any git repository)
def fetch-git-latest [url: string, prefix: string]: nothing -> record {
    let latest = git ls-remote --tags --refs $url
        | lines
        | parse $"{rev}($GIT_TAG_REF_PATTERN){tag}"
        | where { $in.tag | str starts-with $prefix }
        | each {|row|
            let version = $row.tag | str replace -r $"^($prefix)" ""
            $row | insert version $version
        }
        | sort-by-semver
        | last

    { version: $latest.version, rev: $latest.rev }
}

# Fetch latest version from GitHub using gh CLI
def fetch-github-latest [owner: string, repo: string, prefix: string]: nothing -> record {
    # Try releases first
    let release = do -i { gh release view --repo $"($owner)/($repo)" --json tagName } | complete

    if $release.exit_code == 0 {
        let tag = $release.stdout | from json | get tagName
        let version = $tag | str replace -r $"^($prefix)" ""

        if ($version | is-empty) {
            error make { msg: $"Empty version tag from release for ($owner)/($repo)" }
        }

        return { version: $version, rev: null }
    }

    # Fall back to tags with pagination
    fetch-github-tags $owner $repo $prefix
}

# Fetch latest tag from GitHub tags API with pagination (sorted by semver)
def fetch-github-tags [owner: string, repo: string, prefix: string]: nothing -> record {
    let result = do -i { gh api --paginate $"repos/($owner)/($repo)/tags" } | complete

    if $result.exit_code != 0 {
        error make { msg: $"Failed to fetch tags from GitHub: ($result.stderr)" }
    }

    let tags = $result.stdout | from json

    if ($tags | is-empty) {
        error make { msg: $"No releases or tags found for ($owner)/($repo)" }
    }

    let sorted = $tags
        | each {|tag|
            let version = $tag.name | str replace -r $"^($prefix)" ""
            { version: $version, name: $tag.name }
        }
        | sort-by-semver

    if ($sorted | is-empty) {
        error make { msg: $"No valid semver tags found for ($owner)/($repo)" }
    }

    let latest = $sorted | last
    { version: $latest.version, rev: null }
}

# Sort records by semantic version field (Schwartzian transform for efficiency)
# Filters out non-semver versions before sorting
def sort-by-semver []: list<record> -> list<record> {
    $in
    | where {|row| $row.version | is-valid-semver }
    | each {|row|
        let parts = $row.version | split row "." | each { into int }
        $row | insert _sort_key [
            ($parts | get -o 0 | default 0)
            ($parts | get -o 1 | default 0)
            ($parts | get -o 2 | default 0)
        ]
    }
    | sort-by _sort_key
    | reject _sort_key
}

# Check if a version string is valid semver (digits and dots only)
# Intentionally rejects pre-release versions (e.g., 1.0.0-rc1, 2.0.0-beta)
# and build metadata (e.g., 1.0.0+build123) to ensure only stable releases
# are selected when sorting for the latest version.
def is-valid-semver []: string -> bool {
    let cleaned = $in | str replace -a "." ""
    if ($cleaned | is-empty) { return false }
    $cleaned | split chars | all {|c| $c =~ '^\d$' }
}

# Compute hashes and update JSON file
def compute-and-update-hashes [
    meta: record
    latest: record
    json_path: string
    name: string
]: nothing -> record {
    # Back up original state for rollback on failure
    let original = $meta

    try {
        # Prepare updated meta with new version and empty hashes
        let updated = $meta
            | upsert version $latest.version
            | if $meta.sourceType == $SOURCE_TYPE_GIT {
                $in | upsert rev $latest.rev
            } else {
                $in | upsert hash ""
            }
            | upsert vendorHash ""

        save-package-json $json_path $updated

        # Compute source hash (only for github)
        let with_source_hash = if $meta.sourceType == $SOURCE_TYPE_GITHUB {
            print "  Computing source hash..."
            let hash = parse-hash-from-build $name "source"
            $updated | upsert hash $hash
        } else {
            $updated
        }

        save-package-json $json_path $with_source_hash

        # Compute vendor hash
        print "  Computing vendor hash..."
        let vendor_hash = parse-hash-from-build $name "vendor"
        let final = $with_source_hash | upsert vendorHash $vendor_hash

        save-package-json $json_path $final
        $final
    } catch {|err|
        # Restore original on failure
        save-package-json $json_path $original
        error make { msg: $"Hash computation failed: ($err | to text)" }
    }
}

# Save JSON metadata file with atomic write (write to temp, then rename)
def save-package-json [path: string, data: record]: nothing -> nothing {
    let tmp_path = $"($path).tmp"
    $data | to json --indent 2 | save -f $tmp_path
    mv -f $tmp_path $path
}

# Run nix build and parse hash from error output
def parse-hash-from-build [name: string, hash_type: string]: nothing -> string {
    # Use do -i to ignore non-zero exit codes, then capture with complete
    let result = do -i { nix build $"($FLAKE_PKG_PREFIX)($name)" } | complete

    if $result.exit_code == 0 {
        # Build succeeded unexpectedly
        error make { msg: $"Build succeeded unexpectedly during ($hash_type) hash computation" }
    }

    let stderr = $result.stderr

    # Parse hash from "got: sha256-..." pattern
    let hash_lines = $stderr | lines | where { $in | str contains $HASH_PATTERN }

    if ($hash_lines | is-empty) {
        print $"  (ansi red)Error: Could not find hash in build output(ansi reset)"
        print $"  stderr: ($stderr | str substring 0..($ERROR_PREVIEW_LENGTH))"
        error make { msg: $"Could not parse ($hash_type) hash from nix build output for ($name)" }
    }

    let hash = $hash_lines
        | first
        | parse --regex $HASH_REGEX
        | get capture0
        | first

    $hash
}
