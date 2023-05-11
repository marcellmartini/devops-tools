Index
=====
- [Index](#index)
- [Kubernetes role](#kubernetes-role)
  - [Requirements](#requirements)
  - [Role Variables](#role-variables)
  - [Dependencies](#dependencies)
  - [TAGS](#tags)
  - [Example Playbook](#example-playbook)
  - [TODO](#todo)
  - [License](#license)
  - [Author Information](#author-information)

Kubernetes role
=========

The objective of this role is to create a Kubernetes cluster using kubeadm, install the containerd as a container runtime and weave net as Pod network add-on.

It's make all the steps bellow:
* Prepare the hosts
* Initialize your control-plane node
* Install a Pod network add-on (weave net)
* Joining nodes to cluster

> This role was created to implement a Kubernetes cluster with Ubuntu 22.04 servers nodes.

Requirements
------------

To run this `role` the inventory must at least have:
* One node in `[cp]` group;
* The `primary=true` variable must be set only in one control plane node.
* The `hostname` variable must be set on all nodes.

With this configuration, the `role` will configure a Kubernetes with no workers and only one node as the control plane.

The `inventory` file example below is the minimum configuration to run the role:

```ini
[k8s:children]
cp
nodes

[k8s:vars]
primary=false

[cp]
<hostname_or_ip> hostname=cp1 primary=true

[cp:vars]
node_role=cp

[nodes]

[nodes:vars]
node_role=node
```

Exemple of playbook:
```yaml
---
- name: Configure Kubernetes cluster
  gather_facts: true
  hosts: k8s
  remote_user: <remote_user_with_sudo_permission>
  roles:
    - kubernetes
```

Run command:
```bash
$ ansible-playbook -i hosts.ini playbook.yaml
```

In tags sections I'll talk about other options to run the command.

Role Variables
--------------
Variables in `defaults/main.yml`:

|         TAG         |                                               Default Value                                               |                         Explanation                          |
| :-----------------: | :-------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------: |
|     k8s_version     |                                                 "1.26.4"                                                  |   The version of Kubernetes cluster that will be created.    |
|       k8s_cni       |                                                  "weave"                                                  |    The CNI that will be installed in Kubernetes cluster.     |
|  weave_net_upgrade  |                                                  "false"                                                  | Inform is want to upgrade the wave_net to the latest version |
|    weave_net_url    | "https://github.com/weaveworks/weave/releases/download/v{{ weave_net_version }}/weave-daemonset-k8s.yaml" |   The yaml of weave that will be used to install weave net   |
|  weave_net_version  |                                                  "2.8.1"                                                  |        The version of wave net that will be installed        |
| weave_net_yaml_path |                                           "/tmp/weave_net.yaml"                                           |         The place where weave_net.yaml will be saved         |
|      hostname       |                                                    ""                                                     |                           Hostname                           |
|      node_role      |                                                  "node"                                                   |                      Default node role                       |
|       primary       |                                                  "false"                                                  |        Indicate what node is a primary control-plane         |

Dependencies
------------

There is no dependence on roles hosted on Galaxy. This role only uses built-in modules.

TAGS
----------------
To control the behavior of this role, we have the following tags:

* configure
* init
* nodes

The `configure` tag configures all the node requirements to create a Kubernetes cluster.

The `init` tag initiates a Kubernetes cluster in the node where the `primary=true` variable is set.

The `nodes` tag joins the nodes in the Kubernetes cluster that was initiated on the `primary=true` node.

You can use this role with the following behavior:
* Just configure all nodes.
```bash
$ ansible-playbook -i hosts.ini playbook.yaml --tags configure
```

* Create a cluster with one control-plane node only.
```bash
$ ansible-playbook -i hosts.ini playbook.yaml --tags configure,init
```

* Create a cluster with nodes.
```bash
$ ansible-playbook -i hosts.ini playbook.yaml
```

* Join a new node to the existing cluster.
```bash
$ ansible-playbook -i hosts.ini playbook.yaml --tags configure, node
```

Example Playbook
----------------

hosts.ini:
```ini
[k8s:children]
cp
nodes

[k8s:vars]
primary=false

[cp]
<hostname_or_ip> hostname=cp1 primary=true

[cp:vars]
node_role=cp

[nodes]
<hostname_or_ip> hostname=node1
<hostname_or_ip> hostname=node2
<hostname_or_ip> hostname=node3
<hostname_or_ip> hostname=node4

[nodes:vars]
node_role=node

```

playbook.yml:
```yaml
---
- name: Configure Kubernetes cluster
  gather_facts: true
  hosts: k8s
  remote_user: user
  roles:
    - kubernetes
```
Run the playbook:
```bash
$ ansible-playbook -i hosts.ini playbook.yaml
```

With the examples above, this role will create a Kubernetes cluster with one control plane node and four worker nodes:

TODO
----

* Create Molecule tests.
* Configure Github Actions to test the role.
* Create a load balancer.
* Create a cluster with multinode control plane.
* Clean up
* Remove the node
* Clean up the control plane
* Upgarde the cluster against the [version skew policy][vsp]

License
-------

MIT

Author Information
------------------

[Marcell Martini][marcellmartini] is an experienced DevOps/SRE who worked in a production Kubernetes created at AWS.

[marcellmartini]:https://marcellmartini.dev
[vsp]:https://kubernetes.io/releases/version-skew-policy/
