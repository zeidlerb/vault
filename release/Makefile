# Include config.mk relative to the repo root (this allows us to invoke this file
# from different directories safely).
include $(shell git rev-parse --show-toplevel)/release/config.mk

.PHONY: packages commands build package write-builder-cache-keys build-all-layers save-builder-cache load-builder-cache \
	write-package-cache-keys build-all

GOOS ?= $(shell go env GOOS 2>/dev/null || echo linux)
GOARCH ?= $(shell go env GOARCH 2>/dev/null || echo amd64)

PACKAGE_CACHE_KEY_FILES := $(shell yq -r '.packages[].meta.builtin.PACKAGE_CACHE_KEY_FILE' < $(LOCK))
PACKAGE_CACHE_KEY_FILES := $(addprefix $(REPO_ROOT)/,$(PACKAGE_CACHE_KEY_FILES))
#
# MK is shorthand for changing to repo root and selecting a make target
# from a file in this directory. All makefiles in this directory assume
# the current working directory is the repo root.
MK := $(MAKE) -C $(REPO_ROOT) -f $(RELEASE_DIR)/

# configure load-builder-cache target to load the most specific builder layer cache
# available as an archive in the build cache.
ifeq ($(PACKAGE_SPEC_ID),)
load-builder-cache:
	@echo "You must set PACKAGE_SPEC_ID to use this target."; exit 1
else
BUILD_LAYER_ARCHIVES := $(shell yq -r '$(YQ_PACKAGE_PATH) | .meta.builtin.BUILD_LAYERS[].archive' < $(LOCK))
BEST_BUILD_LAYER_ARCHIVE := $(shell cd $(REPO_ROOT) && for F in $(BUILD_LAYER_ARCHIVES); do if [ -f $$F ]; then echo $$F; exit 0; fi; done)
ifeq ($(BEST_BUILD_LAYER_ARCHIVE),)
load-builder-cache:
	@echo "No build layer archives found in build cache. Looked for: $(BUILD_LAYER_ARCHIVES)"; exit 1
else
BEST_BUILD_LAYER_NAME := $(shell yq -r '$(YQ_PACKAGE_PATH) | .meta.builtin.BUILD_LAYERS[] | select(.archive=="$(BEST_BUILD_LAYER_ARCHIVE)") | .name' < $(LOCK))
BEST_BUILD_LAYER_LOAD_TARGET := $(BEST_BUILD_LAYER_NAME)-load
load-builder-cache:
	@$(MK)layer.mk $(BEST_BUILD_LAYER_LOAD_TARGET)
endif
endif

packages:
	@rm -rf packages.lock
	@packagespec lock

commands:
	@$(MAKE) -f packages.mk commands

DEFAULT_PACKAGE_YQ := .packages[] | select(.inputs.GOOS=="$(GOOS)" and .inputs.GOARCH=="$(GOARCH)") 

# build is a convenience target for local builds, do not use in CI.
# Instead, use `make package`.
build: $(LOCK)
	@echo "==> Building default package for GOOS=$(GOOS) GOARCH=$(GOARCH)"
	@echo "SOURCE ID: $(PACKAGE_SOURCE_ID)"
	@ALIASES=$$(yq -r '$(DEFAULT_PACKAGE_YQ) | \
		.aliases[] | "alias type:\(.type) path:\(.path)"' < $(LOCK) | column -t); \
		echo "$$ALIASES"
	@COMMAND=$$(yq -r '$(DEFAULT_PACKAGE_YQ) | \
		.meta.builtin.LOCAL_BUILD_COMMAND' < $(LOCK) | head -n1); \
		echo "$$COMMAND"; \
		$(SHELL) "$$COMMAND"

package:
	@$(MK)build.mk package

write-builder-cache-keys:
	@echo "==> Writing build layer cache keys"
	@$(MK)layer.mk write-cache-keys

build-all-layers:
	@echo "==> Building all builder layers"
	@$(MK)layer.mk build-all-layers

save-builder-cache:
	@echo "==> Exporting Docker build cache"
	@$(MK)layer.mk save-builder-cache

write-package-cache-keys: $(PACKAGE_CACHE_KEY_FILES)
	@echo "==> Package cache keys written:"
	@echo $(PACKAGE_CACHE_KEY_FILES)

.PHONY: $(PACKAGE_CACHE_KEY_FILES)
$(PACKAGE_CACHE_KEY_FILES):
	mkdir -p $(dir $@)
	echo $(PACKAGE_SOURCE_ID) > $@

