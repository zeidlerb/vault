# Include config.mk relative to the repo root (this allows us to invoke this file
# from different directories safely).
include $(shell git rev-parse --show-toplevel)/release/config.mk

.PHONY: packages commands build package write-builder-cache-keys build-all-layers save-builder-cache load-builder-cache \
	write-package-cache-keys build-all

GOOS ?= $(shell go env GOOS 2>/dev/null || echo linux)
GOARCH ?= $(shell go env GOARCH 2>/dev/null || echo amd64)

DEFAULT_PACKAGE_YQ := .packages[] | select(.inputs.GOOS=="$(GOOS)" and .inputs.GOARCH=="$(GOARCH)") 
QUERY_DEFAULT_PACKAGESPEC = $(call QUERY_LOCK,$(DEFAULT_PACKAGE_YQ) | $(1))

PACKAGE_CACHE_KEY_FILES := $(shell $(call QUERY_LOCK,.packages[].meta.builtin.PACKAGE_CACHE_KEY_FILE))
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
BUILD_LAYER_ARCHIVES := $(shell $(call QUERY_PACKAGESPEC,.meta.builtin.BUILD_LAYERS[].archive))
BEST_BUILD_LAYER_ARCHIVE := $(shell cd $(REPO_ROOT) && for F in $(BUILD_LAYER_ARCHIVES); do if [ -f $$F ]; then echo $$F; exit 0; fi; done)
ifeq ($(BEST_BUILD_LAYER_ARCHIVE),)
load-builder-cache:
	@echo "No build layer archives found in build cache. Looked for: $(BUILD_LAYER_ARCHIVES)"; exit 1
else
BEST_BUILD_LAYER_NAME := $(shell $(call QUERY_PACKAGESPEC,.meta.builtin.BUILD_LAYERS[] | select(.archive=="$(BEST_BUILD_LAYER_ARCHIVE)") | .name))
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

# build is a convenience target for local builds, do not use in CI.
# Instead, use `make package` specifying PACKAGE_SPEC_ID.
build:
	@echo "==> Building default package for GOOS=$(GOOS) GOARCH=$(GOARCH)"
	@echo "PACKAGE_SOURCE_ID: $(PACKAGE_SOURCE_ID)"
	@ALIASES=$$($(call QUERY_DEFAULT_PACKAGESPEC,.aliases[] | "alias type:\(.type) path:\(.path)") | column -t); \
		echo "$$ALIASES"
	@PACKAGE_SPEC_ID="$$($(call QUERY_DEFAULT_PACKAGESPEC,.packagespecid) | head -n1)"; \
		COMMAND="PACKAGE_SPEC_ID=$$PACKAGE_SPEC_ID $(MK)build.mk package"; \
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

clean-builder-images:
	@docker images --format '{{.Repository}}:{{.Tag}}' | grep '^$(BUILDER_IMAGE_PREFIX)' || true | xargs docker rmi -f

clean:
	@cd $(REPO_ROOT); rm -rf $(CACHE_ROOT)

clean-all: clean clean-builder-images

.PHONY: $(PACKAGE_CACHE_KEY_FILES)
$(PACKAGE_CACHE_KEY_FILES):
	mkdir -p $(dir $@)
	echo $(PACKAGE_SOURCE_ID) > $@

