SHELL := /usr/bin/env bash -euo pipefail -c

SOURCE := $(shell git ls-files; git ls-files -o --exclude-standard)

COMMIT := $(shell git rev-parse HEAD)

# SOURCE_ID is the ID of all source filesm including anything modified since the git commit.
# It is the sum of the current git commit SHA plus the full contents of all modified files.
SOURCE_ID := $(shell (git ls-files -m | while read -r F; do cat $F 2>/dev/null; done; git rev-parse HEAD) | sha256sum | cut -d' ' -f1)

$(shell mkdir -p .make)

BUILD_BASE_SUM := $(shell sha256sum < build/build-base.Dockerfile | cut -d' ' -f1)
BUILD_BASE_REPO := vault-builder
BUILD_BASE_TAG := $(BUILD_BASE_SUM)
BUILD_BASE_IMAGE := $(BUILD_BASE_REPO):$(BUILD_BASE_TAG)
BUILD_BASE := .make/$(BUILD_BASE_REPO)_$(BUILD_BASE_TAG)

BUILD_STATIC_REPO := vault-builder-static
BUILD_STATIC_TAG := $(SOURCE_ID)
BUILD_STATIC_IMAGE := $(BUILD_STATIC_REPO):$(BUILD_STATIC_TAG)
BUILD_STATIC := .make/$(BUILD_STATIC_REPO)_$(BUILD_STATIC_TAG)

SOURCE_ARCHIVE := .make/source-$(SOURCE_ID).tar.gz

default: help

help:
	@echo SOURCE_ID='$(SOURCE_ID)'
	@echo BUILD_STATIC='$(BUILD_STATIC)'

static: $(BUILD_STATIC)
	@echo "Static image: $<"

base: $(BUILD_BASE)
	@echo "Base image: $(BUILD_BASE_IMAGE)"

# BUILD_BASE is the base docker image, minus any source code.
$(BUILD_BASE): build/build-base.Dockerfile
	docker build -t $(BUILD_BASE_IMAGE) - < $<
	touch $@

$(SOURCE_ARCHIVE): $(SOURCE)
	git ls-files | tar -czf $@ -T -

# BUILD_STATIC is the base docker image, plus source code, with static files built.
# Static files are code and UI assets that do not differ between platforms.
$(BUILD_STATIC): build/build-static.Dockerfile $(SOURCE_ARCHIVE) $(BUILD_BASE)
	docker build \
		--build-arg BASE_IMAGE=$(BUILD_BASE_IMAGE) \
		-f build/build-static.Dockerfile \
		- < $(SOURCE_ARCHIVE)
	touch $@

build: $(BUILD_STATIC)

