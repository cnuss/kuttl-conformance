KREW_ROOT ?= $(HOME)/.krew
export PATH := $(KREW_ROOT)/bin:$(PATH)

.PHONY: install-krew install-kuttl matrix test

## install-krew: install krew kubectl plugin manager if not already present
install-krew:
	@command -v kubectl-krew >/dev/null 2>&1 || { \
		set -e; cd "$$(mktemp -d)" && \
		OS="$$(uname | tr '[:upper:]' '[:lower:]')" && \
		ARCH="$$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$$/arm64/')" && \
		KREW="krew-$${OS}_$${ARCH}" && \
		curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$${KREW}.tar.gz" && \
		tar zxf "$${KREW}.tar.gz" && \
		./"$${KREW}" install krew; \
	}

## install-kuttl: install kuttl via krew
install-kuttl: install-krew
	@command -v kubectl-kuttl >/dev/null 2>&1 || kubectl krew install kuttl

## matrix: emit a JSON list of test-suite names found under e2e/*
##         writes to $GITHUB_OUTPUT when running in GitHub Actions
matrix:
	@suites=$$(ls -d e2e/*/kuttl-test.yaml 2>/dev/null | xargs -n1 dirname | xargs -n1 basename | jq -Rnc '[inputs]'); \
	if [ "$$suites" = "[]" ]; then echo "error: no test suites found" >&2; exit 1; fi; \
	echo "$$suites"; \
	if [ -n "$$GITHUB_OUTPUT" ]; then echo "suites=$$suites" >> "$$GITHUB_OUTPUT"; fi

## test: run tests (SUITE=pods, WHAT=dns-config, or both)
test: install-kuttl
	@config=kuttl-test.yaml; \
	if [ -n "$(SUITE)" ]; then config=e2e/$(SUITE)/kuttl-test.yaml; fi; \
	what=""; \
	if [ -n "$(WHAT)" ]; then what="--test $(WHAT)"; fi; \
	kubectl kuttl test --parallel=4 --start-kind --timeout=120 --config $$config $$what
