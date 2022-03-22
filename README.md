

Run the whole environment on Linux

* Spin up k8s cluster (using kind)

```
./_spin_k8s.sh
```

* Spin up Vault cluster on k8s (using helm)

```
./_spin_vault.sh
```

* Spin up Consul datacenter (using helm)

Add license in `./consul.hclic`

```
./_spin_consul.sh
```

