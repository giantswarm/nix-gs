.PHONY: update flake-update update-sources build check list clean help
.DEFAULT_GOAL := help

PACKAGES := $(patsubst lib/packages/%.json,%,$(wildcard lib/packages/*.json))

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_%-]+:.*?## / { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

update: ## Run full upgrade workflow (flake-update + update-sources + build)
	$(MAKE) flake-update
	$(MAKE) update-sources
	$(MAKE) build

flake-update: ## Update flake inputs
	nix flake update

update-sources: ## Update all package sources
	./bin/update-packages.nu

update-%: ## Update a single package source (e.g. make update-devctl)
	./bin/update-packages.nu $*

build: ## Build all packages
	nix build -v -L --no-link $(addprefix .#,$(PACKAGES))

build-%: ## Build a single package (e.g. make build-devctl)
	nix build -v -L .#$*

check: ## Run nix flake check
	nix flake check -v -L

list: ## List available packages
	./bin/update-packages.nu --list

clean: ## Remove result symlinks
	rm -f result result-*
