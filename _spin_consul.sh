
CLUSTER="dc1"
ASSETS="./assets"
LOGS="./logs"

## Consul config

helm uninstall -n consul consul

helm install -n consul -f ${ASSETS}/consul-values.yaml --debug --wait consul hashicorp/consul --version "0.41.1"

# sleep 30