SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: packages build

packages:
	@$(MAKE) -f packages.mk lock

build:
	@# Run the build makefile as if it were in the repo root.
	@$(MAKE) -C ../ -f release/build/build.mk build
