SHELL := /usr/bin/env bash -euo pipefail

NAME := osc-infra

AWS_REGION ?= us-east-2
env ?= local
ctx ?= kind-$(NAME)
setup_for_k8s = source ./scripts/utils.sh && export TAG=$$(get-image-tag)

create-local:
	@kind create cluster \
		--image docker.io/kindest/node:v1.34.0 \
		--config ./deploy/kind-config.yaml \
		--name $(NAME)
# Metallb requires that we tweak an ARP setting, but since kube-proxy's config isn't a defined
# schema, we can't just `kubectl patch` it, we have to get creative
	@kubectl get -n kube-system configmap/kube-proxy -oyaml \
		| sed 's/strictARP: false/strictARP: true/' \
		| kubectl apply -f-
	@kubectl rollout restart -n kube-system daemonset/kube-proxy

delete-local:
	@kind delete cluster --name $(NAME)

.PHONY: render-manifests
render-manifests:
	@rm -rf ./deploy/rendered
	@bash ./scripts/render-manifests-jsonnet.sh $(env)

.PHONY: deploy
deploy: render-manifests
	@$(setup_for_k8s) && \
		skaffold run

.PHONY: delete-deployments
delete-deployments:
	@$(setup_for_k8s) && \
		skaffold delete

.PHONY: build-only
build-only: render-manifests
	@$(setup_for_k8s) && \
		echo TODO

tail-logs:
	@go run github.com/stern/stern@latest \
		--context $(env) \
		--all-namespaces \
		--selector source-repository=osc-infra \
		--tail=0
