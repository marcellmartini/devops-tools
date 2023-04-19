# Instalação básica

1. baixar o docker
    ```bash
   curl -fSL https://get.docker.com | bash
    ```

1. Baixar [kind][kind-install]
    ```
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.18.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    ```

1. Baixar [kubectl][kubectl-install-debian]
    ```
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo apt-get install -y apt-transport-https

    sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo apt-get update
    sudo apt-get install -y kubectl
    ```

1. Criar um cluster com kind:
    ```
    kind create cluster -f kind_cluster.yml
    ```

# Configuração shell

1. Configurar [bash autocompletion][kubectl-install-autocompletion]
    ```shell
    apt-get install bash-completion
    echo "source /usr/share/bash-completion/bash_completion" >> ~/.bashrc
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
    ```

1. Adicionar alias dentro do `~/.bashrc`:
    ```shell
    alias kgp='kubectl get pod'
    alias kd='kubectl descbribe'
    ```

1. Adicionar algumas variáveis
    ```shell
    export d="--dry-run=client -o yaml"
    ```

    Exemplo de utilização:
    ```shell
    $ kubectl run nginx --image nginx $d
    ```

1. Kubectl [Cheatsheet][kubectl-cheatsheet]

[kind-install]: https://kind.sigs.k8s.io/docs/user/quick-start/#installing-with-a-package-manager

[kubectl-install-debian]: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
[kubectl-install-autocompletion]: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
[kubectl-cheatsheet]: https://kubernetes.io/docs/reference/kubectl/cheatsheet/
