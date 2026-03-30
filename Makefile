CHAINSAW_VERSION ?= v0.2.14
KIND_VERSION ?= v0.31.0
LOCAL_BIN ?= $(HOME)/.local/bin
export PATH := $(LOCAL_BIN):$(PATH)

KIND ?= true
GROUP ?=

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

## matrix: emit JSON list of {group, suite} objects for all test groups
##         groups with suites (e2e/<suite>/<test>/) emit one entry per suite
##         flat groups (smoke/) emit a single entry with empty suite
##         writes to $GITHUB_OUTPUT when running in GitHub Actions
matrix:
	@entries=$$(for group in $$(ls -d */. 2>/dev/null | xargs -n1 dirname); do \
		if ls -d $$group/*/*/chainsaw-test.yaml >/dev/null 2>&1; then \
			for suite in $$(ls -d $$group/*/. 2>/dev/null | xargs -n1 dirname | xargs -n1 basename); do \
				printf '{"group":"%s","suite":"%s"}\n' "$$group" "$$suite"; \
			done; \
		elif ls $$group/chainsaw-test.yaml >/dev/null 2>&1; then \
			printf '{"group":"%s","suite":""}\n' "$$group"; \
		fi; \
	done | jq -sc '.'); \
	if [ "$$entries" = "[]" ] || [ -z "$$entries" ]; then echo "error: no tests found" >&2; exit 1; fi; \
	echo "$$entries"; \
	if [ -n "$$GITHUB_OUTPUT" ]; then echo "matrix=$$entries" >> "$$GITHUB_OUTPUT"; fi

## test: run tests (GROUP=e2e SUITE=pods, WHAT=dns-config, KIND=false)
##       GROUP=smoke runs the smoke group directly (no suites)
test: install-chainsaw
	@if [ "$(KIND)" = "true" ]; then \
		$(MAKE) kind-cluster; \
	fi
	@if [ -n "$(GROUP)" ]; then \
		test_dir=$(GROUP); \
		if [ -n "$(SUITE)" ]; then test_dir=$(GROUP)/$(SUITE); fi; \
	elif [ -n "$(SUITE)" ]; then \
		test_dir=e2e/$(SUITE); \
	else \
		test_dir=e2e; \
	fi; \
	what=""; \
	if [ -n "$(WHAT)" ]; then what="--include-test-regex /$(WHAT)"; fi; \
	chainsaw test --config .chainsaw.yaml --parallel 4 --test-dir $$test_dir $$what
