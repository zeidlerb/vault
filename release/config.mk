# config.mk
#
# config.mk contains constants and derived configuration that applies to
# building both layers and final packages.

# Only include the config once. This means we can include it in the header
# of each makefile, to allow calling them individually and when they call
# each other.
ifneq ($(CONFIG_INCLUDED),YES)
CONFIG_INCLUDED := YES

# Set SHELL to strict mode, in a way compatible with both old and new GNU make.
SHELL := /usr/bin/env bash -euo pipefail -c

REPO_ROOT := $(shell git rev-parse --show-toplevel)

# Set AUTO_INSTALL_TOOLS to YES in CI to have any missing required tools installed
# automatically.
AUTO_INSTALL_TOOLS ?= NO

RELEASE_DIR_REL := release

# RELEASE_DIR is the path to the dir containing all the
# release makefiles etc., relative from the repo root.
# Typically this is 'release'.
RELEASE_DIR := $(REPO_ROOT)/$(RELEASE_DIR_REL)

CACHE_ROOT_REL ?= .buildcache

# CACHE_ROOT is the build cache directory.
CACHE_ROOT ?= $(REPO_ROOT)/$(CACHE_ROOT_REL)

# SPEC is the human-managed description of which packages we are able to build.
SPEC := $(RELEASE_DIR)/packages.yml

# LOCKDIR contains the lockfile and layer files.
LOCKDIR := $(RELEASE_DIR)/packages.lock

# LOCK is the generated fully-expanded rendition of SPEC, for use in generating CI
# pipelines and other things.
LOCK := $(LOCKDIR)/pkgs.yml

# ALWAYS_EXCLUDE_SOURCE prevents source from these directories from taking
# part in the SOURCE_ID, or from being sent to the builder image layers.
# This is important for allowing the head of master to build other commits
# where this build system has not been vendored.
#
# Source in RELEASE_DIR is encoded as PACKAGE_SPEC_ID and included in paths
# and cache keys. Source in .circleci/ should not do much more than call
# code in the release/ directory.
ALWAYS_EXCLUDE_SOURCE     := $(RELEASE_DIR_REL)/ .circleci/
# ALWAYS_EXCLUD_SOURCE_GIT is git path filter parlance for the above.
ALWAYS_EXCLUDE_SOURCE_GIT := ':(exclude)$(RELEASE_DIR_REL)/' ':(exclude).circleci/'

# YQ_PACKAGE_PATH is a yq query fragment to select the package PACKAGE_SPEC_ID.
# This may be invalid, check that PACKAGE_SPEC_ID is not empty before use.
YQ_PACKAGE_PATH := .packages[] | select(.packagespecid == "$(PACKAGE_SPEC_ID)")  

# Even though layers may have different Git revisions, based on the latest
# revision of their source, we always want to
# honour either HEAD or the specified PRODUCT_REVISION for compiling the
# final binaries, as this revision is the one picked by a human to form
# the release.
ifeq ($(PRODUCT_REVISION),)
# If PRODUCT_REVISION is empty (the default) we are concerned with building the
# current work tree, regardless of whether it is dirty or not. For local builds
# this is more convenient and more likely expected behaviour than having to commit
# just to perform a new build.
GIT_REF := HEAD
ALLOW_DIRTY ?= YES
PRODUCT_REVISION_NICE_NAME := <current-workdir>
else
# PRODUCT_REVISION is non-emtpy so treat it as a git commit ref and pull files
# directly from git rather than the work tree.
GIT_REF := $(PRODUCT_REVISION)
ALLOW_DIRTY := NO
PRODUCT_REVISION_NICE_NAME := $(PRODUCT_REVISION)
endif

# Determine the PACKAGE_SOURCE_ID.
# Note we use the GIT_REF suffixed with '^{}' in order to traverse tags down
# to individual commits, which is important in case the GIT_REF is an annotated tag.
ifeq ($(ALLOW_DIRTY),YES)
DIRTY := $(shell git diff --exit-code $(GIT_REF) -- $(ALWAYS_EXCLUDE_SOURCE_GIT) > /dev/null 2>&1 || echo "dirty_")
PACKAGE_SOURCE_ID := $(DIRTY)$(shell git rev-parse $(GIT_REF)^{})
else
PACKAGE_SOURCE_ID := $(shell git rev-parse $(GIT_REF)^{})
endif

# REQ_TOOLS detects availability of a set of tools, and optionally auto-installs them.
define REQ_TOOLS
GROUP_NAME := $(1)
INSTALL_TOOL := $(2)
INSTALL_COMMAND := $(3)
TOOLS := $(4)
TOOL_INSTALL_LOG := $(CACHE_ROOT)/tool-install-$$(GROUP_NAME).log
_ := $$(shell mkdir -p $$(dir $$(TOOL_INSTALL_LOG)))
INSTALL_TOOL_AVAILABLE := $$(shell command -v $$(INSTALL_TOOL) > /dev/null 2>&1 && echo YES)
ATTEMPT_AUTO_INSTALL := NO
ifeq ($$(INSTALL_TOOL_AVAILABLE),YES)
ifeq ($$(AUTO_INSTALL_TOOLS),YES)
ATTEMPT_AUTO_INSTALL := YES
endif
endif
MISSING_PACKAGES := $$(shell \
	for T in $$(TOOLS); do \
		BIN=$$$$(echo $$$$T | cut -d':' -f1); \
	if ! command -v $$$$BIN > /dev/null 2>&1; then \
		echo $$$$T | cut -d':' -f2; \
	fi; \
	done | sort | uniq)
ifneq ($$(MISSING_PACKAGES),)
ifneq ($$(ATTEMPT_AUTO_INSTALL),YES)
$$(error You are missing required tools, please run '$$(INSTALL_COMMAND) $$(MISSING_PACKAGES)'.)
else
RESULT := $$(shell $$(INSTALL_COMMAND) $$(MISSING_PACKAGES) && echo OK > $$(TOOL_INSTALL_LOG))
ifneq ($$(shell cat $$(TOOL_INSTALL_LOG)),OK)
$$(info Failed to auto-install packages with command $$(INSTALL_COMMAND) $$(MISSING_PACKAGES))
$$(error $$(shell cat $$(TOOL_INSTALL_LOG)))
else
$$(info $$(TOOL_INSTALL_LOG))
$$(info Installed tools successfully.)
endif
endif
endif
endef

ifeq ($(shell uname),Darwin)
# On Mac, try to install things with homebrew.
BREW_TOOLS := gln:coreutils gtouch:coreutils gstat:coreutils \
	gtar:gnu-tar gfind:findutils jq:jq yq:python-yq
$(eval $(call REQ_TOOLS,core,brew,brew install,$(BREW_TOOLS)))
else
# If not mac, assume debian and try to install using apt.
APT_TOOLS := pip3:python3-pip jq:jq column:bsdmainutils
$(eval $(call REQ_TOOLS,apt-tools,apt-get,sudo apt-get update && sudo apt-get install -y,$(APT_TOOLS)))
PIP_TOOLS := yq:yq
$(eval $(call REQ_TOOLS,pip-tools,pip3,pip3 install,$(PIP_TOOLS)))

endif

# We rely on GNU touch, tar and ln.
# On macOS, we assume they are installed as gtouch, gtar, gln by homebrew.
ifeq ($(shell uname),Darwin)
TOUCH := gtouch
TAR := gtar
LN := gln
STAT := gstat
FIND := gfind
else
TOUCH := touch
TAR := tar
LN := ln
STAT := stat
FIND := find
endif

### Utilities and constants
GIT_EXCLUDE_PREFIX := :(exclude)
# SUM generates the sha1sum of its input.
SUM := sha1sum | cut -d' ' -f1
# QUOTE_LIST wraps a list of space-separated strings in quotes.
QUOTE := $(shell echo "'")
QUOTE_LIST = $(addprefix $(QUOTE),$(addsuffix $(QUOTE),$(1)))
GIT_EXCLUDE_LIST = $(call QUOTE_LIST,$(addprefix $(1)))
### End utilities and constants.

# End including config once only.
endif
