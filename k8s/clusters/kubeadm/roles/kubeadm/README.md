Role Name
=========

Role to manage a Kubernetes cluster.

Requirements
------------

To run this `role` the inventory must at least have:
* One server in `[cp]` group;
* The `primary=true` variable must be set on the server.
* The `hostname` variable must be set on the server.

With this configuration, the `role` will configure a Kubernetes with no workers and only one server as the control plane.

Below is the minimum `host` file configuration needed to run the role:
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

Role Variables
--------------

k8s_version:
weave_net_yaml:

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

There is no dependence on roles hosted on Galaxy. This role only uses built-in modules.

TAGS
----------------

* install
* init
* nodes

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

MIT

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
