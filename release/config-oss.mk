# config-oss.mk includes some additional config.
# It is automatically included along with the main config.mk.

# PRODUCT_REPO is the official Git repo for this project.
PRODUCT_REPO := git@github.com:hashicorp/vault.git

# PRODUCT_PATH must be unique for every repo.
# A golang-style package path is ideal.
PRODUCT_PATH := github.com/hashicorp/vault

# PRODUCT_CIRCLECI_SLUG is the slug of this repo's CircleCI project.
PRODUCT_CIRCLECI_SLUG ?= gh/hashicorp/vault

# PRODUCT_CIRCLECI_HOST is the host configured to build this repo.
PRODUCT_CIRCLECI_HOST ?= circleci.com
