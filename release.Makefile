# release.Makefile allows efficient building of release binaries.
#
# How it works
# ============
# We first build a base image containing external libraries etc. This image is expected
# to change only when we update the version of Go, or one of the other third party
# dependencies it installs. See build/build-base.Dockerfile.
#
# Based on that base image, every release cycle, we build another base image called the
# static image. This image additionally contains a snapshot of the source code we are
# building, as well as generated static assets, which do not change per target platform.
# (This means the full compiled UI.) See build/build-static.Dockerfile.
# 
# Using this static base image, we can now build the per-platform binaries.
#
# Notes
# =====
# This is designed to be self-contained enough that we can make use of it without recourse
# to an external Docker registry. This is important for performing builds in CircleCI, where
# we do not want to require additional credentials for pushing to remote registries.
#
# In order to share Docker images between jobs in CircleCI, we cache the images created as
# tarballs, meaning they only need to be rebuilt when something has changed.

# Strict mode shell - See https://fieldnotes.tech/how-to-shell-for-compatible-makefiles
SHELL := /usr/bin/env bash -euo pipefail -c

# COMMIT is the Git commit SHA
COMMIT := $(shell git rev-parse HEAD)

# SOURCE_ID identifies an exact instance of the contents of all files in SOURCE.
# To efficiently calculate this, we take the shasum of COMMIT plus the output of 'git diff'.
SOURCE_ID := $(shell { echo $(COMMIT); git diff; } | sha256sum | cut -d' ' -f1)

MAKEDIR := .make/$(SOURCE_ID)

# Ensure the MAKEDIR exists. It is used to keep track of non-file artifacts like
# docker images and containers.
$(shell mkdir -p $(MAKEDIR))

# SOURCE_LIST is a file containing the list of files in SOURCE.
# We write this to a file as it is too long a list to pass around as CLI args.
SOURCE_LIST := $(MAKEDIR)/source-list
$(shell { git ls-files; git ls-files -o --exclude-standard; } | grep -vF release.Makefile > $(SOURCE_LIST))
# Source includes every file tracked by Git, as well as every new file not in .gitignore.
SOURCE := $(shell cat $(SOURCE_LIST))

# BUILD_BASE_SUM is the ID of the build base dockerfile.
BUILD_BASE_SUM := $(shell sha256sum < build/build-base.Dockerfile | cut -d' ' -f1)
BUILD_BASE_REPO := vault-builder
BUILD_BASE_TAG := $(BUILD_BASE_SUM)
BUILD_BASE_IMAGE := $(BUILD_BASE_REPO):$(BUILD_BASE_TAG)
# We use .make not MAKEDIR here, as the base image changes only
# when the base Dockerfile is updated.
BUILD_BASE := .make/$(BUILD_BASE_REPO)_$(BUILD_BASE_TAG)

# UI_DEPS_SOURCE are the files which dictate the UI dependencies.
UI_DEPS_SOURCE := ui/yarn.lock ui/package.json build/build-ui-deps.Dockerfile

# BUILD_UI_DEPS_SUM represents a unique combination of UI_DEPS_SOURCE and the relevant dockerfile.
BUILD_UI_DEPS_SUM := $(shell sha256sum <(cat $(UI_DEPS_SOURCE) build/build-ui-deps.Dockerfile) | cut -d' ' -f1)

# UI_DEPS_SOURCE_ARCHIVE is the archive containing files that dictate the UI dependencies.
UI_DEPS_SOURCE_ARCHIVE := .make/ui-deps-source_$(BUILD_UI_DEPS_SUM).tar.gz

BUILD_UI_DEPS_REPO := vault-builder-ui-deps
BUILD_UI_DEPS_TAG := $(BUILD_UI_DEPS_SUM)
BUILD_UI_DEPS_IMAGE := $(BUILD_UI_DEPS_REPO):$(BUILD_UI_DEPS_TAG)
BUILD_UI_DEPS := .make/$(BUILD_UI_DEPS_REPO)_$(BUILD_UI_DEPS_TAG)

BUILD_STATIC_REPO := vault-builder-static
BUILD_STATIC_TAG := $(SOURCE_ID)
BUILD_STATIC_IMAGE := $(BUILD_STATIC_REPO):$(BUILD_STATIC_TAG)
BUILD_STATIC := $(MAKEDIR)/$(BUILD_STATIC_REPO)_$(BUILD_STATIC_TAG)

# SOURCE_ARCHIVE is the name of the file we use as Docker context when
# building the static image.
SOURCE_ARCHIVE := $(MAKEDIR)/source.tar.gz

## Phonies section (these allow running individual jobs without knowing
## the source ID etc).

default: help

help:
	@echo COMMIT='$(COMMIT)'
	@echo SOURCE_ID='$(SOURCE_ID)'
	@echo SOURCE_DIR=$(SOURCE_DIR)
	@echo BUILD_STATIC='$(BUILD_STATIC)'
	@echo SOURCE_ARCHIVE=$(SOURCE_ARCHIVE)
	@echo DOCKER_RUN_COMMAND=$(DOCKER_RUN_COMMAND)
	@echo PACKAGE=$(PACKAGE)
	@echo BUILD_UI_DEPS_SUM=$(BUILD_UI_DEPS_SUM)
	@echo UI_DEPS_SOURCE_ARCHIVE=$(UI_DEPS_SOURCE_ARCHIVE)

base: $(BUILD_BASE)
	@cat $<

ui-deps: $(BUILD_UI_DEPS)
	@cat $<

static: $(BUILD_STATIC)
	@cat $<

package: $(PACKAGE)
	@cat $<

ui-deps-source-archive: $(UI_DEPS_SOURCE_ARCHIVE)
	@echo $<

source-archive: $(SOURCE_ARCHIVE)
	@echo $<

.PHONY: default help base static package source-archive ui-deps-source-archive

## End phonies, targets below are real files.
#
# SOURCE_ARCHIVE is a tarball of all files not ignored by Git.
# We use this as the Docker context rather than relying on .dockerignore or similar, as it is simpler.
# Note that we do not use 'git archive' because we want to include uncommitted modifications
# during development ('git archive' only includes what's committed). Ensuring that we are building
# from a clean tree in CI will be enforced elsewhere.
$(SOURCE_ARCHIVE): $(SOURCE_LIST)
	tar -czf $@ -T - < $(SOURCE_LIST)

$(UI_DEPS_SOURCE_ARCHIVE): $(UI_DEPS_SOURCE)
	tar -czf $@ $(UI_DEPS_SOURCE)

# BUILD_BASE is the base docker image, minus any source code.
# Note that we invoke docker build by piping in the Dockerfile,
# in order to avoid having context, which we are explicitly avoiding here.
$(BUILD_BASE): build/build-base.Dockerfile
	@echo "==> Building base image (this may take some time)"
	docker build -t $(BUILD_BASE_IMAGE) - < $<
	echo $(BUILD_BASE_IMAGE) > $@

$(SOURCE_LIST): $(SOURCE)
	echo $(SOURCE) > $@

# BUILD_UI_DEPS is the base image plus all external UI dependencies.
$(BUILD_UI_DEPS): $(BUILD_BASE) $(UI_DEPS_SOURCE_ARCHIVE)
	@echo "==> Downloading all UI dependencies"
	docker build \
		--build-arg BASE_IMAGE=$(BUILD_BASE_IMAGE) \
		-f build/build-ui-deps.Dockerfile \
		-t $(BUILD_UI_DEPS_IMAGE) \
		- < $(UI_DEPS_SOURCE_ARCHIVE)
	echo $(BUILD_UI_DEPS_IMAGE) > $@

# BUILD_STATIC is the base docker image, plus source code, with all static files built.
# Static files are code and UI assets that do not differ between platforms.
# We pass SOURCE_ARCHIVE as the context here.
$(BUILD_STATIC): build/build-static.Dockerfile $(SOURCE_ARCHIVE) $(BUILD_UI_DEPS)
	@echo "==> Building static builder image (this may take some time)"
	docker build \
		--build-arg BASE_IMAGE=$(BUILD_UI_DEPS_IMAGE) \
		-f build/build-static.Dockerfile \
		-t $(BUILD_STATIC_IMAGE) \
		- < $(SOURCE_ARCHIVE)
	echo $(BUILD_STATIC_IMAGE) > $@

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
CC ?=
CGO_ENABLED ?= 0
BUILD_VERSION ?= 0.0.0-dev
GO_BUILD_TAGS ?= vault
EDITION :=

BINARY_NAME := vault
PACKAGE_NAME := vault_$(BUILD_VERSION)_$(GOOS)_$(GOARCH)
OUT_DIR:= dist/$(PACKAGE_NAME)
PACKAGE := $(OUT_DIR)/$(PACKAGE_NAME).zip

BUILD_ENV := GO111MODULE=off GOOS=$(GOOS) GOARCH=$(GOARCH) CC=$(CC) CGO_ENABLED=$(CGO_ENABLED)
LDFLAGS := -X github.com/hashicorp/vault/sdk/version.GitCommit='$(COMMIT)'
BUILD_COMMAND := $(BUILD_ENV) go build -v -tags '$(GO_BUILD_TAGS)' -o /$(OUT_DIR)/$(BINARY_NAME)
ARCHIVE_COMMAND := zip /$(PACKAGE) /$(OUT_DIR)/$(BINARY_NAME)
DOCKER_SHELL := /bin/bash -euo pipefail -c
DOCKER_RUN_FLAGS := --rm -v $(CURDIR)/$(OUT_DIR):/$(OUT_DIR)
DOCKER_RUN_COMMAND := 'docker run $(DOCKER_RUN_FLAGS) $(BUILD_STATIC_IMAGE) $(DOCKER_SHELL) "$(BUILD_COMMAND) && $(ARCHIVE_COMMAND)"'

$(PACKAGE): $(BUILD_STATIC)
	@echo "==> Building package: $@"
	@rm -rf ./$(OUT_DIR)
	@mkdir -p ./$(OUT_DIR)
	$(DOCKER_RUN_COMMAND)

