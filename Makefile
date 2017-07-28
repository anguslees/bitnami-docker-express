# Assumes:
#
# 1. `kubecfg` is installed somewhere in $PATH
#    Download from https://github.com/ksonnet/kubecfg/releases/tag/v0.3.0
#
# 2. ksonnet-lib beta.2 is available on disk somewhere
#    git clone https://github.com/ksonnet/ksonnet-lib
#    export KUBECFG_JPATH=$PWD/ksonnet-lib

DOCKER = docker
KUBECFG = kubecfg
MINIKUBE = minikube

# Avoid ":latest" so we also avoid imagePullPolicy=Always
APP_IMAGE = myapp:dev

KCFG_ARGS = -V APP_IMAGE=$(APP_IMAGE)

APP_FILES := \
   $(shell find public routes views bin -type f -print) \
   app.js package.json

# Just generate the yaml, for looking at
all: docker.image kubernetes.yaml

# Actually push to the default kubectl/kubecfg cluster
push: docker.image
	$(KUBECFG) update -v $(KCFG_ARGS) kubernetes.jsonnet

# See result under minikube (assumes already pushed)
view:
	$(MINIKUBE) service myapp

docker.image: Dockerfile $(APP_FILES)
	$(DOCKER) build -t $(APP_IMAGE) -f $< .
	echo $(APP_IMAGE) > $@

%.yaml: %.jsonnet docker.image
	$(KUBECFG) show $(KCFG_ARGS) $< >$@.tmp
	mv $@.tmp $@

test: kubernetes.yaml
	kubectl create --dry-run -f $<
