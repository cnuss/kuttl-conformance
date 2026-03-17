CHAINSAW_VERSION ?= v0.2.14
KIND_VERSION ?= v0.31.0
LOCAL_BIN ?= $(HOME)/.local/bin
export PATH := $(LOCAL_BIN):$(PATH)

KIND ?= true

.PHONY: install-chainsaw install-kind kind-cluster matrix test

## install-chainsaw: download chainsaw binary if not present
install-chainsaw:
	@command -v chainsaw >/dev/null 2>&1 || { \
		set -e; \
		OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
		ARCH=$$(uname -m); \
		case $$ARCH in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; esac; \
		mkdir -p $(LOCAL_BIN); \
		echo "Installing chainsaw $(CHAINSAW_VERSION) for $${OS}/$${ARCH}..."; \
		curl -fsSL "https://github.com/kyverno/chainsaw/releases/download/$(CHAINSAW_VERSION)/chainsaw_$${OS}_$${ARCH}.tar.gz" | \
			tar xz -C $(LOCAL_BIN) chainsaw; \
	}

## install-kind: download kind binary if not present
install-kind:
	@command -v kind >/dev/null 2>&1 || { \
		set -e; \
		OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
		ARCH=$$(uname -m); \
		case $$ARCH in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; esac; \
		mkdir -p $(LOCAL_BIN); \
		echo "Installing kind $(KIND_VERSION) for $${OS}/$${ARCH}..."; \
		curl -fsSLo $(LOCAL_BIN)/kind "https://kind.sigs.k8s.io/dl/$(KIND_VERSION)/kind-$${OS}-$${ARCH}"; \
		chmod +x $(LOCAL_BIN)/kind; \
	}

## kind-cluster: ensure a kind cluster is running
kind-cluster: install-kind
	@kind get clusters 2>/dev/null | grep -q '^kind$$' || kind create cluster --wait 60s

## matrix: emit a JSON list of test-suite names found under e2e/*
##         writes to $GITHUB_OUTPUT when running in GitHub Actions
matrix:
	@suites=$$(ls -d e2e/*/. 2>/dev/null | xargs -n1 dirname | xargs -n1 basename | jq -Rnc '[inputs]'); \
	if [ "$$suites" = "[]" ]; then echo "error: no test suites found" >&2; exit 1; fi; \
	echo "$$suites"; \
	if [ -n "$$GITHUB_OUTPUT" ]; then echo "suites=$$suites" >> "$$GITHUB_OUTPUT"; fi

## test: run tests (SUITE=pods, WHAT=dns-config, KIND=false)
test: install-chainsaw
	@if [ "$(KIND)" = "true" ]; then \
		$(MAKE) kind-cluster; \
	fi
	@test_dir=e2e; \
	if [ -n "$(SUITE)" ]; then test_dir=e2e/$(SUITE); fi; \
	what=""; \
	if [ -n "$(WHAT)" ]; then what="--include-test-regex /$(WHAT)"; fi; \
	chainsaw test --config .chainsaw.yaml --test-dir $$test_dir $$what
