# Everything here runs locally and costs nothing.
# Prerequisites: docker, kind, kubectl (+ helm for monitoring). See README.

SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

APP_SRC ?= ../portfolio
export APP_SRC

.PHONY: help up build deploy test monitoring down lint tf-check

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Create the kind cluster, build the image, deploy and smoke test
	./scripts/up.sh

build: ## Build the site image only
	./scripts/build.sh

deploy: ## Re-apply manifests to the kind cluster and smoke test
	kind load docker-image ghcr.io/neoslinkee/portfolio:dev --name portfolio
	./scripts/deploy.sh kind

test: ## Run the smoke tests against the running cluster
	./scripts/smoke-test.sh

monitoring: ## Install Prometheus + Grafana with the portfolio dashboard and alerts
	./scripts/monitoring.sh

down: ## Delete the kind cluster
	./scripts/down.sh

lint: ## Render and validate manifests, lint Dockerfile and scripts
	@mkdir -p .rendered
	kubectl kustomize k8s/overlays/kind > .rendered/kind.yaml
	kubectl kustomize k8s/overlays/aks > .rendered/aks.yaml
	kubeconform -strict -summary -ignore-missing-schemas .rendered/*.yaml
	hadolint app/Dockerfile
	shellcheck -x scripts/*.sh

tf-check: ## fmt + validate + tflint the AKS stack (no Azure account needed)
	cd infra/terraform/aks && terraform fmt -check -recursive && terraform init -backend=false -input=false >/dev/null && terraform validate && tflint --init >/dev/null && tflint
