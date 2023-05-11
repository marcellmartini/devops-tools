# Install cluster with kubeadm

## Steps
1. [install reqs][k8s-req-install]
    ```bash
    $ cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    $ sudo modprobe overlay
    $ sudo modprobe br_netfilter

    # sysctl params required by setup, params persist across reboots
    $ cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables  = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    # Apply sysctl params without reboot
    $ sudo sysctl --system

    # Validate steps
    $ lsmod | grep br_netfilter
    $ lsmod | grep overlay

    $ sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
    ```

1. CGroups
    Using the [default cgroups][default-cgroups]:

1. Install containerd
    ```bash
    # Install
    $ sudo apt update
    $ sudo apt -y install **containerd**

    # Configure default
    $ sudo mkdir -p /etc/containerd
    $ containerd config default | sudo tee /etc/containerd/config.toml
    $ sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

    # Restart containerd
    $ sudo systemctl restart containerd.service

    # Check status
    $ systemctl status containerd.service
    ```
2. Swap off
    ```bash
    # Turn off the swap
    $ sudo swapoff -a

    # Turn off the swap permanently
    $ sudo sed -e '/swap/ s/^#*/#/' -i /etc/fstab
    $ sudo systemctl mask swap.target
    ```

3. [Installing kubeadm, kubelet and kubectl][install-kube{adm,let,ctl}] version `v1.26.4` with apt:
    ```bash
    # Install Kubectl
    $ sudo apt-get update
    $ sudo apt-get install -y ca-certificates curl
    $ sudo apt-get install -y apt-transport-https
    $ sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    $ echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" |
        sudo tee /etc/apt/sources.list.d/kubernetes.list
    $ sudo apt-get update
    $ sudo apt-get install -y kubeadm=1.26.4-00 kubelet=1.26.4-00 kubectl=1.26.4-00
    ```
    5.1. [Enable shell autocompletion][k8s-shell-autocomplete] #TODO

    5.2 Install [K9S][k9s-install]:
    ```bash
    $ curl -sS https://webinstall.dev/k9s | bash
    ```

    5.3 Configure alias para rodar crictl
    ```bash
    $ echo alias crictl=\'sudo crictl --runtime-endpoint unix:///run/containerd/containerd.sock\' |
        tee -a ~/.bashrc
    ```

4. [Creating a cluster with kubeadm][kubeadm-init]
    ```bash
    # Iniciar o k8s
    $ sudo kubeadm init

    # Configurar o kubeconf
    $ mkdir -p $HOME/.kube
    $ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```


[k8s-req-install]:https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites
[default-cgroups]:https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroupfs-cgroup-driver
[install-kube{adm,let,ctl}]:https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
[k8s-shell-autocomplete]:https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#enable-shell-autocompletion
[kubeadm-init]:https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
[k9s-install]:https://github.com/derailed/k9s
