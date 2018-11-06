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
```console
$ ip link add veth0 type veth peer name veth1
$ ip link list
$ ip link set veth1 netns <namespace name>
```


## Systemd nspawn
