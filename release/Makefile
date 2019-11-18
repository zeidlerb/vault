# Include config.mk relative to this file (this allows us to invoke this file
# from different directories safely).
include $(shell dirname $(lastword $(MAKEFILE_LIST)))/config.mk

.PHONY: packages build

REPO_ROOT := $(shell git rev-parse --show-toplevel) 
GOOS ?= $(shell go env GOOS 2>/dev/null || echo linux)
GOARCH ?= $(shell go env GOARCH 2>/dev/null || echo amd64)

packages:
	@# Remove layers.lock entirely to avoid buildup of old layers.
	@# Easier to do that here than in packages.mk.
	@rm -rf layers.lock
	@$(MAKE) -f packages.mk lock

commands:
	@$(MAKE) -f packages.mk commands

build: .tmp/default-package-index commands
	@echo "==> Building default package for GOOS=$(GOOS) GOARCH=$(GOARCH)"
	@cat .tmp/commands/$$(cat $<).sh
	@$(SHELL) "$$(cat .tmp/commands/$$(cat $<).sh)"

write-builder-cache-keys:
	@echo "==> Writing build layer cache keys"
	@$(MAKE) -C ../ -f release/layer.mk write-cache-keys

build-all-layers:
	@echo "==> Building all builder layers"
	@(MAKE) -C ../ -f release/layer.mk build-all-layers

save-builder-cache:
	@echo "==> Exporting Docker build cache"
	@$(MAKE) -C ../ -f release/layer.mk save-builder-cache

load-builder-cache:
	@echo "==> Loading Docker build cache"
	@$(MAKE) -C ../ -f release/layer.mk load-builder-cache

write-package-cache-keys: $(PACKAGE_CACHE_KEY_FILES)
	@echo "==> Package cache keys written to $<"

build-all: commands
	cd ../ && $(SHELL) "$$(cat release/.tmp/all-commands.sh)"

# .tmp/default-package-index contains the index of the default package to build on this system.
# Its only significance is to make the 'make build' command build something relevant for this
# machine by default. (The command files are 1-indexed for fun, hence the .key + 1.)
.PHONY: .tmp/default-package-index
.tmp/default-package-index: packages.lock
	@mkdir -p .tmp
	@yq -r '.packages | to_entries | .[] | select(.value.GOOS=="$(GOOS)" and .value.GOARCH=="$(GOARCH)") | .key + 1' < packages.lock | head -n1 > $@

.PHONY: $(PACKAGE_CACHE_KEY_FILES)
$(PACKAGE_CACHE_KEY_FILES):
	@rm -rf $@; mkdir -p $@
	@grep -F 'PACKAGE_SPEC_ID:' < $(LOCK) | cut -d':' -f2 | while read -r ID; do \
		echo $(PACKAGE_SOURCE_ID) > $@/package-$$ID; \
	done
