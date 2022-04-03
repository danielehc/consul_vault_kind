### Prerequisites

* `kubectl`
* `vault` binary
* `consul` binaries

If you do not want to install `consul` and `vault` globally, create a `bin` folder
in the repository root and download the binaries there, the scripts include that 
folder in the `PATH` when running.

### Run the environment

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

### Resources

https://gist.github.com/lamadome/1756fb2923a2a873e8707a3a7806fcb1

https://gist.github.com/kschoche/3f773230426ca6e52d11b86e0122ef25