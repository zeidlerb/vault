SHELL := /usr/bin/env bash -euo pipefail
PKG_COUNT := $(shell yq '.packages | length' < package-list.yml)
MAKEFLAGS += -j$(PKG_COUNT)

LIST := package-spec.yml
TEMPLATES := .tmp/templates

DEFAULTS_DIR := .tmp/defaults
RENDERED_DIR := .tmp/rendered
PACKAGES_DIR := .tmp/packages
LOCKFILE := .tmp/packages-expanded

$(shell mkdir -p $(DEFAULTS_DIR) $(PACKAGES_DIR) $(RENDERED_DIR))

PKG_INDEXES := $(shell seq $(PKG_COUNT))

DEFAULTS := $(addprefix $(DEFAULTS_DIR)/,$(addsuffix .json,$(PKG_INDEXES)))
RENDERED := $(addprefix $(RENDERED_DIR)/,$(addsuffix .json,$(PKG_INDEXES)))
PACKAGES := $(addprefix $(PACKAGES_DIR)/,$(addsuffix .json,$(PKG_INDEXES)))

lockfile: $(LOCKFILE)
	@cat $<

packages: $(PACKAGES)
	@cat $^

rendered: $(RENDERED)
	@cat $^

defaults: $(DEFAULTS)
	@cat $^

templates: $(TEMPLATES)
	@find $< -mindepth 1 -maxdepth 1 | while read R; do echo "==> $$R"; cat $$R; done

$(LOCKFILE): $(PACKAGES)
	@jq -s . $$(find $(PACKAGES)) | yq -y . >$@

$(PACKAGES_DIR)/%.json: $(DEFAULTS_DIR)/%.json $(RENDERED_DIR)/%.json 
	@jq -s '.[0] + .[1]' $^ > $@

$(RENDERED_DIR)/%.json: $(DEFAULTS_DIR)/%.json $(TEMPLATES)
	@OUT=$@.yml; rm -f $$OUT; \
	find $(TEMPLATES) -mindepth 1 -maxdepth 1 | while read -r T; do \
	  TNAME=$$(basename $$T); \
	  echo -n "$$TNAME: " >> $$OUT; \
	  cat $< | gomplate -f $$T -d vars=$< | xargs >> $$OUT; \
	done; \
	yq . < $$OUT > $@; rm -f $$OUT

$(DEFAULTS_DIR)/%.json: $(LIST) Makefile
	@yq -c '[ .defaults as $$defaults | .packages[$*-1] | $$defaults + . ][]' < $(LIST) > $@

$(TEMPLATES): $(LIST) Makefile
	@rm -rf $@; mkdir -p $@
	@yq -r '.templates | keys[]' < $< | while read -r NAME; do \
		echo -n '{{$$d := (datasource "vars")}}{{with $$d}}' > $@/$$NAME; \
		yq -r ".templates.$$NAME" $< >> $@/$$NAME; \
		echo "{{end}}" >> $@/$$NAME; \
	done
