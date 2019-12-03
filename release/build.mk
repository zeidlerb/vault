#/$(PACKAGE_ZIP_NAME) build.mk
#
# build.mk builds the packages defined in packages.lock, first building all necessary
# builder images.
#
# NOTE: This file should always run as though it were in the repo root, so all paths
# are relative to the repo root.

# Include config.mk relative to this file (this allows us to invoke this file
# from different directories safely.
include $(shell dirname $(lastword $(MAKEFILE_LIST)))/config.mk

# Make sure we have all the necessary inputs.
# Ensure all of these are set in packages.lock
ifeq ($(PACKAGE_SPEC_ID),)
$(error You must set PACKAGE_SPEC_ID, try invoking 'make build' instead.)
endif

# Include the layers driver.
include $(RELEASE_DIR)/layer.mk

# Should be set by layer.mk.
ifeq ($(BUILD_LAYER_IMAGE_NAME),)
$(error You must set BUILDER_LAYER_IMAGE_NAME)
endif
ifeq ($(BUILD_LAYER_IMAGE),)
$(error You must set BUILDER_LAYER_IMAGE)
endif

YQ_PACKAGE_PATH := .packages[] | select(.packagespecid == "$(PACKAGE_SPEC_ID)")  

BUILD_ENV := $(shell yq -r '$(YQ_PACKAGE_PATH) | .inputs | to_entries[] | "\(.key)=\(.value)"' < $(LOCK))
BUILD_COMMAND := $(shell yq -r '$(YQ_PACKAGE_PATH) | .["build-command"]' < $(LOCK))

ifeq ($(BUILD_ENV),)
$(error Unable to find build inputs for package spec ID $(PACKAGE_SPEC_ID))
endif
ifeq ($(BUILD_COMMAND),)
$(error Unable to find build command for package spec ID $(PACKAGE_SPEC_ID))
endif

FULL_BUILD_COMMAND := export $(BUILD_ENV) && $(BUILD_COMMAND)

OUTPUT_DIR := $(CACHE_ROOT)/packages
_ := $(shell mkdir -p $(OUTPUT_DIR))
# PACKAGE_NAME is the input-addressed name of the package.
PACKAGE_NAME := $(PACKAGE_SOURCE_ID)-$(PACKAGE_SPEC_ID)
PACKAGE_ZIP_NAME := $(PACKAGE_NAME).zip
PACKAGE := $(OUTPUT_DIR)/$(PACKAGE_ZIP_NAME)
META_YAML_NAME := $(PACKAGE_NAME)-meta.yml
META := $(OUTPUT_DIR)/$(META_YAML_NAME)

### Docker run command configuration.

DOCKER_SHELL := /bin/bash -euo pipefail -c

DOCKER_RUN_ENV_FLAGS := \
	-e PACKAGE_SOURCE_ID=$(PACKAGE_SOURCE_ID) \
	-e OUTPUT_DIR=/$(OUTPUT_DIR) \
	-e PACKAGE_ZIP_NAME=$(PACKAGE_ZIP_NAME)

BUILD_CONTAINER_NAME := build-$(PACKAGE_SPEC_ID)-$(PACKAGE_SOURCE_ID)
DOCKER_RUN_FLAGS := $(DOCKER_RUN_ENV_FLAGS) --name $(BUILD_CONTAINER_NAME)
# DOCKER_RUN_COMMAND ties everything together to build the final package as a
# single docker run invocation.
DOCKER_RUN_COMMAND = docker run $(DOCKER_RUN_FLAGS) $(BUILD_LAYER_IMAGE_NAME) $(DOCKER_SHELL) '$(FULL_BUILD_COMMAND)'
DOCKER_CP_COMMAND = docker cp $(BUILD_CONTAINER_NAME):/$(OUTPUT_DIR)/$(PACKAGE_ZIP_NAME) $(PACKAGE)

.PHONY: package
package: $(PACKAGE)
	@echo $<

$(META): $(LOCK)
	yq -y '.packages[] | select(.packagespecid == "$(PACKAGE_SPEC_ID)")' < $(LOCK) > $@

# PACKAGE builds the package.
$(PACKAGE): $(BUILD_LAYER_IMAGE) $(META)
	@mkdir -p $$(dirname $@)
	@echo "==> Building package: $@"
	@docker rm -f $(BUILD_CONTAINER_NAME) > /dev/null 2>&1 || true # Speculative cleanup.
	$(DOCKER_RUN_COMMAND)
	$(DOCKER_CP_COMMAND)
	@docker rm -f $(BUILD_CONTAINER_NAME)

source-id:
	@echo $(PACKAGE_SOURCE_ID)
