KUTTL_VERSION ?= 0.25.0

.PHONY: install-kuttl matrix test

## install-kuttl: download kuttl CLI if not already present
install-kuttl:
	@command -v kubectl-kuttl >/dev/null 2>&1 || { \
		curl -fsSL "https://github.com/kudobuilder/kuttl/releases/download/v$(KUTTL_VERSION)/kubectl-kuttl_$(KUTTL_VERSION)_linux_x86_64" \
			-o /usr/local/bin/kubectl-kuttl && \
		chmod +x /usr/local/bin/kubectl-kuttl; \
	}

## matrix: emit a JSON list of test-suite names found under tests/e2e/*
matrix:
	@suites=$$(ls -d tests/e2e/*/kuttl-test.yaml 2>/dev/null | xargs -n1 dirname | xargs -n1 basename | jq -Rnc '[inputs]'); \
	if [ "$$suites" = "[]" ]; then echo "error: no test suites found" >&2; exit 1; fi; \
	echo "$$suites"

## test: run a single test suite  (SUITE=pods)
test:
	@test -n "$(SUITE)" || { echo "usage: make test SUITE=<name>"; exit 1; }
	kubectl kuttl test --config tests/e2e/$(SUITE)/kuttl-test.yaml
