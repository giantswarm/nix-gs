.PHONY: update check

update:
	./bin/update-packages.nu

check:
	nix flake check -v -L
