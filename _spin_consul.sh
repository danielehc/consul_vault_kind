
CLUSTER="dc1"
ASSETS="./assets"
LOGS="./logs"

## Consul config

helm uninstall -n consul consul

helm install -n consul -f ${ASSETS}/consul-values.yaml --debug --wait consul hashicorp/consul --version "0.41.1"

sleep 30

# kubectl port-forward -n consul consul-server-0 8500:8500 > ${LOGS}/port_forward_consul.log 2>&1 &
kubectl port-forward -n consul service/consul-ui 8443:443 > ./logs/port_forward_consul.log 2>&1 &

export CONSUL_HTTP_ADDR="https://localhost:8443"
export CONSUL_TLS_SERVER_NAME="server.dc1.consul"
# export CONSUL_CACERT="${ASSETS}/consul_ca.crt"
export CONSUL_HTTP_SSL_VERIFY=false


kubectl port-forward -n consul service/consul-ui 8501:443 > ./logs/port_forward_consul.log 2>&1 &

