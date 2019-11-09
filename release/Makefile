SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: package-list package-lock package

package-list:
	@$(MAKE) -f package-spec.Makefile list

package-lock:
	@$(MAKE) -f package-spec.Makefile package-spec.lock

package:
	@$(MAKE) -f package.Makefile -C ../ package

