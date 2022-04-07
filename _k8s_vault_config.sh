
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

export token_reviewer_jwt="`kubectl exec --stdin=true --tty=true vault-0 -n vault -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`"
# export kubernetes_ca_cert="`kubectl exec --stdin=true --tty=true vault-0 -n vault -- awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' /var/run/secrets/kubernetes.io/serviceaccount/ca.crt`"
export kubernetes_ca_cert="`kubectl exec --stdin=true --tty=true vault-0 -n vault -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt`"
export kubernetes_port_443_tcp_addr=`kubectl exec --stdin=true --tty=true vault-0 -n vault -- /bin/sh -c 'echo -en $KUBERNETES_PORT_443_TCP_ADDR'`

kubectl proxy &

export kubernetes_issuer=`curl --silent http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer`

kill %%

# kubectl exec --stdin=true --tty=true vault-0 -n vault -- \
vault write auth/kubernetes/config \
  token_reviewer_jwt="${token_reviewer_jwt}" \
  kubernetes_host="https://${kubernetes_port_443_tcp_addr}:443" \
  # issuer="${kubernetes_issuer}" \
  disable_iss_validation=true \
  kubernetes_ca_cert="${kubernetes_ca_cert}"
# Success! Data written to: auth/kubernetes/config

set +x