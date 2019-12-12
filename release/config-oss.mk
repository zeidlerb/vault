# config-oss.mk includes some additional config.
# It is automatically included along with the main config.mk.
build-ci: PRODUCT_NAME ?= vault
build-ci: PRODUCT_REVISION ?= $(shell git rev-parse HEAD)
build-ci: PRODUCT_VERSION ?= 0.0.0-$(USER)-snapshot
build-ci: PRODUCT_REPO ?= git@github.com:hashicorp/vault.git
build-ci: PRODUCT_CIRCLECI_SLUG ?= gh/hashicorp/vault
build-ci: PRODUCT_CIRCLECI_HOST ?= circleci.com
build-ci: RELEASE_SYSTEM_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)

export PRODUCT_NAME PRODUCT_REVISION PRODUCT_VERSION PRODUCT_REPO PRODUCT_CIRCLECI_SLUG PRODUCT_CIRCLECI_HOST RELEASE_SYSTEM_BRANCH

# SPEC and LOCKDIR should already be set by the main config file.
export SPEC LOCKDIR
