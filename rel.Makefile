SHELL := /usr/bin/env bash -euo pipefail

CACHE_ROOT := .buildcache
ALL_SOURCE_LIST := $(CACHE_ROOT)/current-source

GIT_EXCLUDE_PREFIX := :(exclude)

SUM := sha1sum | cut -d' ' -f1

QUOTE_LIST = $(addprefix ',$(addsuffix ',$(1)))

define LAYER
NAME           = $(1)
BASE           = $(2)
SOURCE_INCLUDE = $(3)
SOURCE_EXCLUDE = $(4)

CACHE = $(CACHE_ROOT)/$$(NAME)/$$(SOURCE_ID)
SOURCE_LIST = $$(CACHE)/source-list
DOCKERFILE = build/$$(NAME).Dockerfile
IMAGE_NAME = vault-builder-$$(NAME):$$(SOURCE_ID)

SOURCE_GIT = $$(SOURCE_INCLUDE) $$(DOCKERFILE) $$(call QUOTE_LIST,$$(addprefix $$(GIT_EXCLUDE_PREFIX),$$(SOURCE_EXCLUDE)))
SOURCE_CMD = { \
			 	git ls-files HEAD -- $$(SOURCE_GIT); \
			 	git ls-files -m --exclude-standard HEAD -- $$(SOURCE_GIT); \
			 } | sort | uniq

	
SOURCE_COMMIT       = $$(shell git rev-list -n1 HEAD -- $$(SOURCE_GIT))
SOURCE_MODIFIED     = $$(shell if git diff -s --exit-code -- $$(SOURCE_GIT); then echo NO; else echo YES; fi)
SOURCE_MODIFIED_SUM = $$(shell git diff -- $$(SOURCE_GIT) | $(SUM))
SOURCE_NEW          = $$(shell git ls-files -o --exclude-standard -- $$(SOURCE_GIT))
SOURCE_NEW_SUM      = $$(shell git ls-files -o --exclude-standard -- $$(SOURCE_GIT) | $(SUM))
SOURCE_DIRTY        = $$(shell if [ $$(SOURCE_MODIFIED) == NO ] && [ -z "$$(SOURCE_NEW)" ]; then echo NO; else echo YES; fi)
SOURCE_ID           = $$(shell if [ $$(SOURCE_MODIFIED) == NO ] && [ -z "$$(SOURCE_NEW)" ]; then \
								   echo $$(SOURCE_COMMIT); \
				      		   else \
								   echo -n dirty_; echo $$(SOURCE_MODIFIED_SUM) $$(SOURCE_NEW_SUM) | $(SUM); \
							   fi)

_ = $$(shell mkdir -p $$(CACHE) && $$(SOURCE_CMD) > $$(SOURCE_LIST))

PHONY_TARGET_NAMES := debug build save load
PHONY_TARGETS := $$(addprefix $$(NAME)-,$$(PHONY_TARGET_NAMES))

.PHONY: $$(PHONY_TARGETS)

# File targets.
IMAGE             = $$(CACHE)/image.name
IMAGE_TIMESTAMP   = $$(CACHE)/image.created_time
IMAGE_ARCHIVE     = $$(CACHE)/image.tar.gz

TARGETS = $$(PHONY_TARGETS)

# Fix all variables for use in targets.
$$(TARGETS): NAME                := $$(NAME)
$$(TARGETS): BASE                := $$(BASE)
$$(TARGETS): SOURCE_GIT          := $$(SOURCE_GIT)
$$(TARGETS): SOURCE_CMD          := $$(SOURCE_CMD)
$$(TARGETS): SOURCE_GREP         := $$(SOURCE_GREP)
$$(TARGETS): SOURCE_COMMIT       := $$(SOURCE_COMMIT)
$$(TARGETS): SOURCE_MODIFIED     := $$(SOURCE_MODIFIED)
$$(TARGETS): SOURCE_MODIFIED_SUM := $$(SOURCE_MODIFIED_SUM)
$$(TARGETS): SOURCE_ID           := $$(SOURCE_ID)
$$(TARGETS): SOURCE_NEW          := $$(SOURCE_NEW)
$$(TARGETS): SOURCE_NEW_SUM      := $$(SOURCE_NEW_SUM)
$$(TARGETS): SOURCE_DIRTY        := $$(SOURCE_DIRTY)
$$(TARGETS): IMAGE               := $$(IMAGE)
$$(TARGETS): IMAGE_TIMESTAMP     := $$(IMAGE_TIMESTAMP)
$$(TARGETS): IMAGE_ARCHIVE       := $$(IMAGE_ARCHIVE)
$$(TARGETS): TARGETS             := $$(TARGETS)

$$(NAME)-debug:
	@echo "==> Debug info: $$(NAME) depends on $$(BASE)"
	@echo "TARGETS         = $$(TARGETS)"
	@echo "SOURCE_CMD      = $$(SOURCE_CMD)"
	@echo "SOURCE_LIST     = $$(SOURCE_LIST)"
	@echo "CACHE           = $$(CACHE)"
	@echo "DOCKERFILE      = $$(DOCKERFILE)"
	@echo "SOURCE_COMMIT   = $$(SOURCE_COMMIT)"
	@echo "SOURCE_ID       = $$(SOURCE_ID)"
	@echo "SOURCE_MODIFIED = $$(SOURCE_MODIFIED)"
	@echo "SOURCE_DIRTY    = $$(SOURCE_DIRTY)"
	@echo "SOURCE_NEW      = $$(SOURCE_NEW)"
	@echo "IMAGE           = $$(IMAGE)"
	@echo "IMAGE_TIMESTAMP = $$(IMAGE_TIMESTAMP)"
	@echo "IMAGE_ARCHIVE   = $$(IMAGE_ARCHIVE)"
	@cat $$(SOURCE_LIST) | wc -l
	@echo

$$(NAME)-image:
	@echo "==> Building image: $$(IMAGE)"

endef

BASE_NAME           := base
BASE_BASEIMAGE      :=
BASE_SOURCE_INCLUDE := build/base.Dockerfile
BASE_SOURCE_EXCLUDE := 
$(eval $(call LAYER,$(BASE_NAME),$(BASE_BASEIMAGE),$(BASE_SOURCE_INCLUDE),$(BASE_SOURCE_EXCLUDE)))

YARN_NAME           := yarn
YARN_BASEIMAGE      := base
YARN_SOURCE_INCLUDE := ui/yarn.lock ui/package.json
YARN_SOURCE_EXCLUDE :=
$(eval $(call LAYER,$(YARN_NAME),$(YARN_BASEIMAGE),$(YARN_SOURCE_INCLUDE),$(YARN_SOURCE_EXCLUDE)))

UI_NAME           := ui
UI_BASEIMAGE      := yarn
UI_SOURCE_INCLUDE := ui/
UI_SOURCE_EXCLUDE :=
$(eval $(call LAYER,$(UI_NAME),$(UI_BASEIMAGE),$(UI_SOURCE_INCLUDE),$(UI_SOURCE_EXCLUDE)))

STATIC_NAME           := static
STATIC_BASEIMAGE      := ui
STATIC_SOURCE_INCLUDE := .
STATIC_SOURCE_EXCLUDE := rel.Makefile release.Makefile .circleci/
$(eval $(call LAYER,$(STATIC_NAME),$(STATIC_BASEIMAGE),$(STATIC_SOURCE_INCLUDE),$(STATIC_SOURCE_EXCLUDE)))
