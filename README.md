# Manual Containers

Understand Linux underlying technologies for containers.



## Namespaces

### Network namespace

  - Create network namespace
```console
$ ip netns add <namespace name>
```
  - List network namespace
```console
$ ip netns list
```
  - Assign interface to network namespace

Assign a veth to a namespace :
```console
# create veth pair
$ ip link add veth0 type veth peer name veth1
$ ip link list
# assign one to the namespace
$ ip link set veth1 netns <namespace name>
$ ip link list
$ ip netns exec <namespace name> ip link list
```

Assign a physical interface to a namespace :
```console
$ ip link set dev <physdev> netns <namespace>
```

## Systemd nspawn
