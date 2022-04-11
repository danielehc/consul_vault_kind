
CLUSTER="dc1"
ASSETS="./assets"
LOGS="./logs"

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=`cat ./cluster-keys.json | jq -r ".root_token"`

export PATH=$PATH:./bin

## k8s auth configuration

set -x 
vault auth enable kubernetes
# Success! Enabled kubernetes auth method at: kubernetes/

vault write auth/kubernetes-dc1/config kubernetes_host=https://kubernetes.default.svc
# Success! Data written to: auth/kubernetes/config

set +x
