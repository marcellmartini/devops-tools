define KIND_PATH
	$(shell command -v kind)
endef

.PHONY: kind-install
kind-install:
	@if [ -z ${KIND_PATH} ]; then\
		echo "installing kind in /usr/local/bin path";\
		curl --silent -Lo ./kind https://kind.sigs.k8s.io/dl/v0.18.0/kind-linux-amd64;\
    	chmod +x ./kind;\
    	sudo mv ./kind /usr/local/bin;\
	fi

.PHONY: kind-cluster-create
kind-cluster-create: kind-install
	@kind create cluster --config ./k8s/clusters/kind/kind_cluster.yml --name test

.PHONY: kind-cluster-delete
kind-cluster-delete: kind-install
	@kind delete cluster --name test
