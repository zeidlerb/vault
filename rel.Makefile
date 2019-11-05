SHELL := /usr/bin/env bash -euo pipefail

### Base configuration
CACHE_ROOT := .buildcache
ALL_SOURCE_LIST := $(CACHE_ROOT)/current-source
### End base configuration

### Utilities and constants
GIT_EXCLUDE_PREFIX := :(exclude)
# SUM generates the sha1sum of its input.
SUM := sha1sum | cut -d' ' -f1
# QUOTE_LIST wraps a list of space-separated strings in quotes.
QUOTE := $(shell echo "'")
QUOTE_LIST = $(addprefix $(QUOTE),$(addsuffix $(QUOTE),$(1)))

# TOUCH is the GNU touch utility. On Darwin, you should 'brew install coreutils'
# which will install gtouch. gtouch can parse standard date formats to update the
# modified time of docker image marker files based on info from the docker daemon.
TOUCH := touch
ifeq ($(shell uname),Darwin)
TOUCH := gtouch
endif
### End utilities and constants.

### END BUILDER IMAGE LAYERS

## LAYER

# The LAYER macro defines all the targets for each image defined above.
#
# The phony targets are the ones we typically run ourselves or in CI, they are:
#
#   <name>-debug     : dump debug info for this image layer
#   <name>-image     : build the image for this image layer
#   <name>-save      : save the docker image for this layer as a tar.gz
#   <name>-restore   : restore this image from a saved tar.gz

define LAYER
$(1)_NAME           = $(1)
$(1)_BASE           = $(2)
$(1)_SOURCE_INCLUDE = $(3)
$(1)_SOURCE_EXCLUDE = $(4)

$(1)_CURRENT_LINK = $(CACHE_ROOT)/$$($(1)_NAME)/current
$(1)_CACHE = $(CACHE_ROOT)/$$($(1)_NAME)/$$($(1)_SOURCE_ID)
$(1)_SOURCE_LIST = $$($(1)_CACHE)/source.list
$(1)_DOCKERFILE = build/$$($(1)_NAME).Dockerfile
$(1)_IMAGE_NAME = vault-builder-$$($(1)_NAME):$$($(1)_SOURCE_ID)
$(1)_SOURCE_GIT = $$($(1)_SOURCE_INCLUDE) $$($(1)_DOCKERFILE) $$(call QUOTE_LIST,$$(addprefix $(GIT_EXCLUDE_PREFIX),$$($(1)_SOURCE_EXCLUDE)))
$(1)_SOURCE_CMD = { \
					  echo $$($(1)_DOCKERFILE); \
					  git ls-files HEAD -- $$($(1)_SOURCE_GIT); \
			 		  git ls-files -m --exclude-standard HEAD -- $$($(1)_SOURCE_GIT); \
			 	  } | sort | uniq
	
$(1)_SOURCE_COMMIT       = $$(shell git rev-list -n1 HEAD -- $$($(1)_SOURCE_GIT))
$(1)_SOURCE_MODIFIED     = $$(shell if git diff -s --exit-code -- $$($(1)_SOURCE_GIT); then echo NO; else echo YES; fi)
$(1)_SOURCE_MODIFIED_SUM = $$(shell git diff -- $$($(1)_SOURCE_GIT) | $(SUM))
$(1)_SOURCE_NEW          = $$(shell git ls-files -o --exclude-standard -- $$($(1)_SOURCE_GIT))
$(1)_SOURCE_NEW_SUM      = $$(shell git ls-files -o --exclude-standard -- $$($(1)_SOURCE_GIT) | $(SUM))
$(1)_SOURCE_DIRTY        = $$(shell if [ $$($(1)_SOURCE_MODIFIED) == NO ] && [ -z "$$($(1)_SOURCE_NEW)" ]; then echo NO; else echo YES; fi)
$(1)_SOURCE_ID           = $$(shell if [ $$($(1)_SOURCE_MODIFIED) == NO ] && [ -z "$$($(1)_SOURCE_NEW)" ]; then \
								   echo $$($(1)_SOURCE_COMMIT); \
				      		   else \
								   echo -n dirty_; echo $$($(1)_SOURCE_MODIFIED_SUM) $$($(1)_SOURCE_NEW_SUM) | $(SUM); \
							   fi)

# Ensure the source list is written, the cache dir exists and the current link is up to date.
_ := $$(shell \
	mkdir -p $$($(1)_CACHE); \
	if [ ! -f $$($(1)_SOURCE_LIST) ]; then $$($(1)_SOURCE_CMD) > $$($(1)_SOURCE_LIST); fi;)

$(1)_SOURCE := $$(shell cat $$($(1)_SOURCE_LIST))

$(1)_PHONY_TARGET_NAMES := debug image save load

$(1)_PHONY_TARGETS := $$(addprefix $$($(1)_NAME)-,$$($(1)_PHONY_TARGET_NAMES))

.PHONY: $$($(1)_PHONY_TARGETS)

# File targets.
$(1)_IMAGE             := $$($(1)_CACHE)/image.marker
$(1)_IMAGE_TIMESTAMP   := $$($(1)_CACHE)/image.created_time
$(1)_IMAGE_ARCHIVE     := $$($(1)_CACHE)/image.tar.gz
$(1)_SOURCE_ARCHIVE    := $$($(1)_CACHE)/source.tar.gz

$(1)_IMAGE_LINK        := $(CACHE_ROOT)/$$($(1)_NAME)/current/image.marker

$(1)_BASE_IMAGE        := $$(shell [ -z $$($(1)_BASE) ] || echo $(CACHE_ROOT)/$$($(1)_BASE)/current/image.marker)

$(1)_TARGETS = $$($(1)_PHONY_TARGETS)

# UPDATE_MARKER_FILE ensures the image marker file has the same timestamp as the
# docker image creation date it represents. This enables make to only rebuild it when
# it has really changed, especially after loading the image from an archive.
define $(1)_UPDATE_MARKER_FILE
	export MARKER=$$($(1)_IMAGE); \
	export IMAGE=$$($(1)_IMAGE_NAME); \
	export IMAGE_CREATED; \
	if ! IMAGE_CREATED=$$$$(docker inspect -f '{{.Created}}' $$$$IMAGE 2>/dev/null); then \
		if [ -f $$$$MARKER ]; then \
			echo "==> Removing stale marker file for $$$$IMAGE"; \
			rm -f $$$$MARKER; \
		fi; \
		exit 0; \
	fi; \
	if [ ! -f $$$$MARKER ]; then \
		echo "==> Writing marker file for $$$$IMAGE (created $$$$IMAGE_CREATED)"; \
	fi; \
	echo $$$$IMAGE > $$$$MARKER; \
	$(TOUCH) -m -d $$$$IMAGE_CREATED $$$$MARKER;
endef

## PHONY targets
$(1)-debug:
	@echo "==> Debug info: $$($(1)_NAME) depends on $$($(1)_BASE)"
	@echo "$(1)_TARGETS               = $$($(1)_TARGETS)"
	@echo "$(1)_SOURCE_CMD            = $$($(1)_SOURCE_CMD)"
	@echo "$(1)_SOURCE_LIST           = $$($(1)_SOURCE_LIST)"
	@echo "$(1)_CACHE                 = $$($(1)_CACHE)"
	@echo "$(1)_DOCKERFILE            = $$($(1)_DOCKERFILE)"
	@echo "$(1)_SOURCE_COMMIT         = $$($(1)_SOURCE_COMMIT)"
	@echo "$(1)_SOURCE_ID             = $$($(1)_SOURCE_ID)"
	@echo "$(1)_SOURCE_MODIFIED       = $$($(1)_SOURCE_MODIFIED)"
	@echo "$(1)_SOURCE_DIRTY          = $$($(1)_SOURCE_DIRTY)"
	@echo "$(1)_SOURCE_NEW            = $$($(1)_SOURCE_NEW)"
	@echo "$(1)_IMAGE_LINK            = $$($(1)_IMAGE_LINK)"
	@echo "$(1)_IMAGE                 = $$($(1)_IMAGE)"
	@echo "$(1)_IMAGE_TIMESTAMP       = $$($(1)_IMAGE_TIMESTAMP)"
	@echo "$(1)_IMAGE_ARCHIVE         = $$($(1)_IMAGE_ARCHIVE)"
	@echo "$(1)_BASE_IMAGE            = $$($(1)_BASE_IMAGE)"
	@cat $$($(1)_SOURCE_LIST) | wc -l
	@echo

$(1)-image: $$($(1)_IMAGE_LINK)
	@cat $$<

$(1)-save: $$($(1)_IMAGE_ARCHIVE)
	@echo $$<

$(1)-load:
	@\
		ARCHIVE=$$($(1)_IMAGE_ARCHIVE); \
		IMAGE=$$($(1)_IMAGE_NAME); \
		MARKER=$$($(1)_IMAGE); \
		rm -f $$$$MARKER; \
		echo "==> Loading $$$$IMAGE image from $$$$ARCHIVE"; \
		docker load -i $$$$ARCHIVE
	@$$(call $(1)_UPDATE_MARKER_FILE)

## END PHONY targets

$$($(1)_IMAGE_LINK): | $$($(1)_IMAGE)
	@echo "==> Linking $$($(1)_NAME) cache dir as $$@"
	@ln -fhs $$($(1)_SOURCE_ID) $$($(1)_CURRENT_LINK)

$(1)_DOCKER_BUILD_ARGS=$$(shell [ -z "$$($(1)_BASE)" ] || echo --build-arg BASE_IMAGE=$$$$(cat $$($(1)_BASE_IMAGE)))

$$($(1)_IMAGE): | $$($(1)_BASE_IMAGE) $$($(1)_SOURCE_ARCHIVE)
	@echo "==> Building Docker image: $$($(1)_NAME); $$($(1)_SOURCE_ID)"
	docker build -t $$($(1)_IMAGE_NAME) $$($(1)_DOCKER_BUILD_ARGS) -f $$($(1)_DOCKERFILE) - < $$($(1)_SOURCE_ARCHIVE)
	@$$(call $(1)_UPDATE_MARKER_FILE)

$$($(1)_SOURCE_ARCHIVE): $$($(1)_SOURCE)
	@echo "==> Building source archive: $$($(1)_NAME); $$($(1)_SOURCE_ID)"
	tar czf $$@ -T - < $$($(1)_SOURCE_LIST)

$$($(1)_IMAGE_ARCHIVE): | $$($(1)_IMAGE)
	@echo "==> Saving $(1) image to $$@"
	@docker save -o $$@ $$$$(cat $$($(1)_IMAGE))

endef

### END LAYER

### BUILDER_IMAGE_LAYERS

# Each grouping below defines a layer of the builder image.
# Each definition includes:
#
#   1. The name of the image layer to build (each has a corresponding file in
#      build/<name>.Dockerfile) (required)
#   2. The name of the base image layer (defined in another grouping)
#      if this is left blank, then we just rely on the Dockerfile FROM line.
#   3. Source include: a list of files and directories to consider the source
#      for this layer. Keep this list minimal in order to benefit from caching.
#      Each layer includes own Dockerfile by default. (required)
#   4. Source exclude: a list of files and directories to exclude.
#      This filter is applied after source include, so you can e.g. include .
#      and then just filter our the stuff you do not want.

# The base image contains base dependencies like libraries and tools.
BASE_NAME           := base
BASE_BASEIMAGE      :=
BASE_SOURCE_INCLUDE := build/base.Dockerfile
BASE_SOURCE_EXCLUDE := 
$(eval $(call LAYER,$(BASE_NAME),$(BASE_BASEIMAGE),$(BASE_SOURCE_INCLUDE),$(BASE_SOURCE_EXCLUDE)))

# The yarn image contains all the UI dependencies for the ui layer.
YARN_NAME           := yarn
YARN_BASEIMAGE      := base
YARN_SOURCE_INCLUDE := ui/yarn.lock ui/package.json
YARN_SOURCE_EXCLUDE :=
$(eval $(call LAYER,$(YARN_NAME),$(YARN_BASEIMAGE),$(YARN_SOURCE_INCLUDE),$(YARN_SOURCE_EXCLUDE)))

# The ui image contains the compiled ui code in ui/
UI_NAME           := ui
UI_BASEIMAGE      := yarn
UI_SOURCE_INCLUDE := ui/
UI_SOURCE_EXCLUDE :=
$(eval $(call LAYER,$(UI_NAME),$(UI_BASEIMAGE),$(UI_SOURCE_INCLUDE),$(UI_SOURCE_EXCLUDE)))

# The static image is the one we finally use for compilation of the source.
STATIC_NAME           := static
STATIC_BASEIMAGE      := ui
STATIC_SOURCE_INCLUDE := .
STATIC_SOURCE_EXCLUDE := rel.Makefile release.Makefile .circleci/
$(eval $(call LAYER,$(STATIC_NAME),$(STATIC_BASEIMAGE),$(STATIC_SOURCE_INCLUDE),$(STATIC_SOURCE_EXCLUDE)))

base_UPDATED   := $(strip $(shell $(call base_UPDATE_MARKER_FILE)))
yarn_UPDATED   := $(strip $(shell $(call yarn_UPDATE_MARKER_FILE)))
ui_UPDATED     := $(strip $(shell $(call ui_UPDATE_MARKER_FILE)))
static_UPDATED := $(strip $(shell $(call static_UPDATE_MARKER_FILE)))

ifneq ($(base_UPDATED),)
$(info $(base_UPDATED))
endif

ifneq ($(yarn_UPDATED),)
$(info $(yarn_UPDATED))
endif

ifneq ($(ui_UPDATED),)
$(info $(ui_UPDATED))
endif

ifneq ($(static_UPDATED),)
$(info $(static_UPDATED))
endif

# PACKAGE_OUT_ROOT is the root directory where the final packages will be written to.
PACKAGE_OUT_ROOT ?= dist

### Non-source build inputs (override these when invoking make to produce alternate binaries).
### See build/package-list.txt and build/package-list.lock, which override these
### per package.

## Standard Go env vars.
GOOS ?= $(shell go env GOOS || echo linux)
GOARCH ?= $(shell go env GOARCH || echo amd64)
CC ?= gcc
CGO_ENABLED ?= 0
GO111MODULE ?= off

# GO_BUILD_TAGS is a comma-separated list of Go build tags, passed to -tags flag of 'go build'.
GO_BUILD_TAGS ?= vault

### Package parameters.

# BINARY_NAME is literally the name of the product's binary file.
BINARY_NAME ?= vault
# PRODUCT_NAME is the top-level name of all editions of this product.
PRODUCT_NAME ?= vault
# BUILD_VERSION is the major/minor/prerelease fields of the version.
BUILD_VERSION ?= 0.0.0
# BUILD_PRERELEASE is the prerelease field of the version. If nonempty, it must begin with a -.
BUILD_PRERELEASE ?= -dev
# EDITION is used to differentiate alternate builds of the same commit, which may differ in
# terms of build tags or other build inputs. EDITION should always form part of the BUNDLE_NAME,
# and if non-empty MUST begin with a +.
EDITION ?=

### Calculated package parameters.

FULL_VERSION := $(BUILD_VERSION)$(BUILD_PRERELEASE)
# BUNDLE_NAME is the name of the release bundle.
BUNDLE_NAME ?= $(PRODUCT_NAME)$(EDITION)
# PACKAGE_NAME is the unique name of a specific build of this product.
PACKAGE_NAME = $(BUNDLE_NAME)_$(FULL_VERSION)_$(GOOS)_$(GOARCH)
PACKAGE_FILENAME = $(PACKAGE_NAME).zip
# PACKAGE is the zip file containing a specific binary.
PACKAGE = $(OUT_DIR)/$(PACKAGE_FILENAME)

### Calculated build inputs.

# LDFLAGS: These linker commands inject build metadata into the binary.
LDFLAGS += -X github.com/hashicorp/vault/sdk/version.GitCommit="$(static_SOURCE_ID)"
LDFLAGS += -X github.com/hashicorp/vault/sdk/version.Version="$(BUILD_VERSION)"
LDFLAGS += -X github.com/hashicorp/vault/sdk/version.VersionPrerelease="$(BUILD_PRERELEASE)"

# OUT_DIR tells the Go toolchain where to place the binary.
OUT_DIR := $(PACKAGE_OUT_ROOT)/$(PACKAGE_NAME)/$(static_SOURCE_ID)
# BUILD_ENV is the list of env vars that are passed through to 'make package' and 'go build'.
BUILD_ENV := \
	GO111MODULE=$(GO111MODULE) \
	GOOS=$(GOOS) \
	GOARCH=$(GOARCH) \
	CC=$(CC) \
	CGO_ENABLED=$(CGO_ENABLED) \
	BUILD_VERSION=$(BUILD_VERSION) \
	BUILD_PRERELEASE=$(BUILD_PRERELEASE)

# BUILD_COMMAND compiles the Go binary.
BUILD_COMMAND := \
	$(BUILD_ENV) go build -v \
	-tags '$(GO_BUILD_TAGS)' \
	-ldflags '$(LDFLAGS)' \
	-o /$(OUT_DIR)/$(BINARY_NAME)

# ARCHIVE_COMMAND creates the package archive from the binary.
ARCHIVE_COMMAND := cd /$(OUT_DIR) && zip $(PACKAGE_FILENAME) $(BINARY_NAME)

### Docker run command configuration.

DOCKER_SHELL := /bin/bash -euo pipefail -c
DOCKER_RUN_FLAGS := --rm -v $(CURDIR)/$(OUT_DIR):/$(OUT_DIR)
# DOCKER_RUN_COMMAND ties everything together to build the final package as a
# single docker run invocation.
DOCKER_RUN_COMMAND = docker run $(DOCKER_RUN_FLAGS) $(static_IMAGE_NAME) $(DOCKER_SHELL) "$(BUILD_COMMAND) && $(ARCHIVE_COMMAND)"

.PHONY: package
package: $(PACKAGE)
	@echo $<

# PACKAGE assumes 'make static-image' has already been run.
# It does not depend on the static image, as this simplifies cached later re-use
# on circleci.
$(PACKAGE): $(static_IMAGE)
	@mkdir -p $$(dirname $@)
	@echo "==> Building package: $@"
	@rm -rf ./$(OUT_DIR)
	@mkdir -p ./$(OUT_DIR)
	$(DOCKER_RUN_COMMAND)
