SHELL := /usr/bin/env bash -euo pipefail

CACHE_ROOT := .buildcache
ALL_SOURCE_LIST := $(CACHE_ROOT)/current-source

GIT_EXCLUDE_PREFIX := :(exclude)

SUM := sha1sum | cut -d' ' -f1

QUOTE_LIST = $(addprefix ',$(addsuffix ',$(1)))

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
$(1)_SOURCE_GIT = $$($(1)_SOURCE_INCLUDE) $$($(1)_DOCKERFILE) $$(call QUOTE_LIST,$$(addprefix $$($(1)_GIT_EXCLUDE_PREFIX),$$($(1)_SOURCE_EXCLUDE)))
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


$(1)-debug:
	@echo "==> Debug info: $$($(1)_NAME) depends on $$($(1)_BASE)"
	@echo "$(1)_TARGETS         = $$($(1)_TARGETS)"
	@echo "$(1)_SOURCE_CMD      = $$($(1)_SOURCE_CMD)"
	@echo "$(1)_SOURCE_LIST     = $$($(1)_SOURCE_LIST)"
	@echo "$(1)_CACHE           = $$($(1)_CACHE)"
	@echo "$(1)_DOCKERFILE      = $$($(1)_DOCKERFILE)"
	@echo "$(1)_SOURCE_COMMIT   = $$($(1)_SOURCE_COMMIT)"
	@echo "$(1)_SOURCE_ID       = $$($(1)_SOURCE_ID)"
	@echo "$(1)_SOURCE_MODIFIED = $$($(1)_SOURCE_MODIFIED)"
	@echo "$(1)_SOURCE_DIRTY    = $$($(1)_SOURCE_DIRTY)"
	@echo "$(1)_SOURCE_NEW      = $$($(1)_SOURCE_NEW)"
	@echo "$(1)_IMAGE_LINK      = $$($(1)_IMAGE_LINK)"
	@echo "$(1)_IMAGE           = $$($(1)_IMAGE)"
	@echo "$(1)_IMAGE_TIMESTAMP = $$($(1)_IMAGE_TIMESTAMP)"
	@echo "$(1)_IMAGE_ARCHIVE   = $$($(1)_IMAGE_ARCHIVE)"
	@echo "$(1)_BASE_IMAGE      = $$($(1)_BASE_IMAGE)"
	@cat $$($(1)_SOURCE_LIST) | wc -l
	@echo

$(1)-image: $$($(1)_IMAGE_LINK)
	@cat $$<

#.PHONY: $$($(1)_IMAGE_LINK)
$$($(1)_IMAGE_LINK): $$($(1)_IMAGE)
	@echo "==> Linking $$($(1)_NAME) image as $$@"
	ln -fhs $$($(1)_SOURCE_ID) $$($(1)_CURRENT_LINK)

$(1)_DOCKER_BUILD_ARGS=$$(shell [ -z "$$($(1)_BASE)" ] || echo --build-arg BASE_IMAGE=$$$$(cat $$($(1)_BASE_IMAGE)))

$$($(1)_IMAGE): $$($(1)_BASE_IMAGE) $$($(1)_SOURCE_ARCHIVE)
	@echo "==> Building Docker image: $$($(1)_NAME); $$($(1)_SOURCE_ID)"
	docker build -t $$($(1)_IMAGE_NAME) $$($(1)_DOCKER_BUILD_ARGS) -f $$($(1)_DOCKERFILE) - < $$($(1)_SOURCE_ARCHIVE)
	@echo $$($(1)_IMAGE_NAME) > $$@
	ln -fhs $$($(1)_SOURCE_ID) $$($(1)_CURRENT_LINK)

$$($(1)_SOURCE_ARCHIVE): $$($(1)_SOURCE)
	@echo "==> Building source archive: $$(NAME); $$($(1)_SOURCE_ID)"
	tar czf $$@ -T - < $$($(1)_SOURCE_LIST)

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
