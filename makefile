SHELL := /bin/bash

# ==============================================================================
# Testing running system

# Access metrics directly (4000) or through the sidecar (3001)
# go install github.com/divan/expvarmon@latest
# expvarmon -ports=":4000" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"
# hey -m GET -c 100 -n 10000 -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/v1/users/1/2
# hey -m GET -c 100 -n 10000 http://localhost:3000/test
# 
# Test Auth
# curl -il http://localhost:3000/testauth
# curl -H "Authorization: Bearer ${TOKEN}" http://localhost:3000/testauth
# 
# DBLab
# dblab --host 0.0.0.0 --user postgres --db postgres --pass postgres --ssl disable --port 5432 --driver postgres
# ==============================================================================

run:
	go run app/services/sales-api/main.go

test:
	go test ./...
# staticcheck -checks=all ./...

run-fmt:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

build:
	go build -ldflags "-X main.build=local"

VERSION := 1.0

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.sales-api \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Administration

migrate:
	go run app/tooling/sales-admin/main.go migrate

seed: migrate
	go run app/tooling/sales-admin/main.go seed
# ==============================================================================
# Modules support

deps-reset:
	git checkout -- go.mod
	go mod tidy
	go mod vendor

tidy:
	go mod tidy
	go mod vendor

deps-upgrade:
	# go get $(go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all)
	go get -u -v ./...
	go mod tidy
	go mod vendor

deps-cleancache:
	go clean -modcache

list:
	go list -mod=mod all
# ==============================================================================
# Running from within k8s/kind
# Running from within k8s/kind

KIND_CLUSTER := ardan-starter-cluster

# Upgrade to latest Kind (>=v0.11): e.g. brew upgrade kind
# For full Kind v0.11 release notes: https://github.com/kubernetes-sigs/kind/releases/tag/v0.11.0
# Kind release used for our project: https://github.com/kubernetes-sigs/kind/releases/tag/v0.11.1
# The image used below was copied by the above link and supports both amd64 and arm64.

kind-up:
	kind create cluster \
		--image kindest/node:v1.23.0@sha256:49824ab1727c04e56a21a5d8372a402fcd32ea51ac96a2706a12af38934f81ac \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=sales-system

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

kind-restart:
	kubectl rollout restart deployment sales-pod

kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

kind-status-sales:
	kubectl get pods -o wide --watch

kind-status-db:
	kubectl get pods -o wide --watch --namespace=database-system

kind-load:
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:$(VERSION)
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-apply:
	kustomize build zarf/k8s/kind/database-pod | kubectl apply -f -
	kubectl wait --namespace=database-system --timeout=120s --for=condition=Available deployment/database-pod
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -

kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100

kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply kind-restart

kind-describe:
	kubectl describe pod -l app=sales