SHELL := /usr/bin/env bash -euo pipefail

CACHE_ROOT := .buildcache
ALL_SOURCE_LIST := $(CACHE_ROOT)/current-source

GIT_EXCLUDE_PREFIX := :(exclude)

SUM := sha1sum | cut -d' ' -f1

QUOTE_LIST = $(addprefix ',$(addsuffix ',$(1)))

define DO
$(shell cat <<EOF > $(1)\
$(2); \
EOF \
./$(1); \
)
endef

define LAYER
NAME           = $(1)
BASE           = $(2)
SOURCE_INCLUDE = $(3)
SOURCE_EXCLUDE = $(4)

CACHE = $(CACHE_ROOT)/$$(NAME)
SOURCE_LIST = $$(CACHE)/source-list
DOCKERFILE = build/$$(NAME).Dockerfile

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
								   echo git_$$(SOURCE_COMMIT); \
				      		   else \
								   echo -n dirty_; echo $$(SOURCE_MODIFIED_SUM) $$(SOURCE_NEW_SUM) | $(SUM); \
							   fi)

_ = $$(shell mkdir -p $$(CACHE) && $$(SOURCE_CMD) > $$(SOURCE_LIST))

debug-$$(NAME): NAME                := $$(NAME)
debug-$$(NAME): BASE                := $$(BASE)
debug-$$(NAME): SOURCE_GIT          := $$(SOURCE_GIT)
debug-$$(NAME): SOURCE_CMD          := $$(SOURCE_CMD)
debug-$$(NAME): SOURCE_GREP         := $$(SOURCE_GREP)
debug-$$(NAME): SOURCE_COMMIT       := $$(SOURCE_COMMIT)
debug-$$(NAME): SOURCE_MODIFIED     := $$(SOURCE_MODIFIED)
debug-$$(NAME): SOURCE_MODIFIED_SUM := $$(SOURCE_MODIFIED_SUM)
debug-$$(NAME): SOURCE_ID           := $$(SOURCE_ID)
debug-$$(NAME): SOURCE_NEW          := $$(SOURCE_NEW)
debug-$$(NAME): SOURCE_NEW_SUM      := $$(SOURCE_NEW_SUM)
debug-$$(NAME): SOURCE_DIRTY        := $$(SOURCE_DIRTY)


debug-$$(NAME):
	@echo "==> Debug info: $$(NAME) depends on $$(BASE)"
	@echo "SOURCE_CMD      = $$(SOURCE_CMD)"
	@echo "SOURCE_LIST     = $$(SOURCE_LIST)"
	@echo "CACHE           = $$(CACHE)"
	@echo "DOCKERFILE      = $$(DOCKERFILE)"
	@echo "SOURCE_COMMIT   = $$(SOURCE_COMMIT)"
	@echo "SOURCE_ID       = $$(SOURCE_ID)"
	@echo "SOURCE_MODIFIED = $$(SOURCE_MODIFIED)"
	@echo "SOURCE_DIRTY    = $$(SOURCE_DIRTY)"
	@echo "SOURCE_NEW      = $$(SOURCE_NEW)"
	@cat $$(SOURCE_LIST) | wc -l
	@echo
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
STATIC_SOURCE_EXCLUDE := release.Makefile .circleci/
$(eval $(call LAYER,$(STATIC_NAME),$(STATIC_BASEIMAGE),$(STATIC_SOURCE_INCLUDE),$(STATIC_SOURCE_EXCLUDE)))
