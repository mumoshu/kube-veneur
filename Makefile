VENEUR_PATH = $(shell pwd)/go/veneur/src/github.com/stripe/veneur
EXAMPLE_PATH =$(shell pwd)/go/src/github.com/mumoshu/kube-veneur/example

all: docker-build docker-push example-all

example/bin/example: $(EXAMPLE_PATH)
	docker run -v $(PWD)/example/bin:/go/bin \
	-v $(EXAMPLE_PATH):/go/src/github.com/mumoshu/kube-veneur/example \
	golang:1.7 go get -tags netgo -installsuffix netgo -v --ldflags '-extldflags "-static"' github.com/mumoshu/kube-veneur/example

example-all: example/bin/example
	cd example && docker build -t mumoshu/kube-veneur-example:latest . && docker push mumoshu/kube-veneur-example:latest

docker-push:
	docker push mumoshu/kube-veneur:latest

docker-run: docker-build
	docker run -v $(PWD)/example:/example -e VENEUR_DEBUG=false -e VENEUR_ENABLE_PROFILING=false -e VENEUR_HOSTNAME=veneur-test -e VENEUR_TAG_NAMESPACE=mynamespace -e VENEUR_FORWARD_ADDRESS= mumoshu/kube-veneur:latest

docker-run-confd-test: docker-build
	mkdir -p test-results
	docker run --rm -v $(PWD)/test-results/:/veneur -e VENEUR_DEBUG=false -e VENEUR_ENABLE_PROFILING=false -e VENEUR_HOSTNAME=veneur-test -e VENEUR_TAG_NAMESPACE=mynamespace -e VENEUR_FORWARD_ADDRESS= mumoshu/kube-veneur:latest sleep 1 && cat test-results/veneur.yaml

docker-build: bin/veneur bin/confd s6-overlay
	docker build -t mumoshu/kube-veneur:latest .

$(VENEUR_PATH):
	mkdir -p $(VENEUR_PATH)
	git clone git@github.com:stripe/veneur.git $(VENEUR_PATH)

bin/veneur: $(VENEUR_PATH)
	docker run \
	-v $(PWD)/bin:/go/bin \
	-v $(VENEUR_PATH):/go/src/github.com/stipe/veneur \
	-it golang:1.7 go get -tags netgo -installsuffix netgo -v --ldflags '-extldflags "-static"' github.com/stripe/veneur/cmd/veneur

bin/confd:
	scripts/build-confd

bin/kubectl:
	mkdir -p kubectl
	curl -L https://dl.k8s.io/v1.5.1/kubernetes-client-linux-amd64.tar.gz | tar zxv -C kubectl && mv kubectl/kubernetes/client/bin/kubectl bin/kubectl

bin/jq:
	curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o bin/jq && chmod +x bin/jq

s6-overlay:
	mkdir s6-overlay
	curl -L https://github.com/just-containers/s6-overlay/releases/download/v1.17.1.1/s6-overlay-amd64.tar.gz | tar xvz -C s6-overlay \
	&& rm -f /tmp/s6-overlay.tar.gz

.PHONY: docker-build

delete:
	kubectl delete -f global-veneur.yaml  --namespace kube-system
	kubectl delete -f local-veneur.yaml  --namespace kube-system
	kubectl delete -f local-veneur.yaml  --namespace test-namespace

apply:
	kubectl apply -f global-veneur.yaml  --namespace kube-system
	kubectl apply -f local-veneur.yaml  --namespace kube-system
	kubectl apply -f local-veneur.yaml  --namespace test-namespace

pods:
	kubectl get po --all-namespaces

define SECRET_YAML
apiVersion: v1
kind: Secret
metadata:
  name: veneur
type: Opaque
data:
  key: $(shell bash -c 'echo -n "$$VENEUR_KEY" | base64')
endef
export SECRET_YAML

veneur.secret.yaml:
	echo "$$SECRET_YAML" > veneur.secret.yaml

create-secret: veneur.secret.yaml
	kubectl apply -f veneur.secret.yaml --namespace kube-system
	kubectl apply -f veneur.secret.yaml --namespace test-namespace
