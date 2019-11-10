SHELL := /usr/bin/env bash -euo pipefail -c

.PHONY: package-list package-lock package

package-list:
	@$(MAKE) -f package-spec.Makefile list

package-lock:
	@$(MAKE) -f package-spec.Makefile package-spec.lock

package:
	@# Run the package makefile as if it were in the repo root.
	@$(MAKE) -f release/package.Makefile -C ../ package

