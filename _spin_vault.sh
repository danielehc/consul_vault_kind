
CLUSTER="dc1"
ASSETS="./assets"
LOGS="./logs"

## Vault config

helm uninstall -n vault vault

helm install -n vault --create-namespace -f ${ASSETS}/vault-values.yaml --debug --wait vault hashicorp/vault --version "0.20.0"

echo "Sleeping 50 seconds"
sleep 50

set -x

kubectl port-forward -n vault vault-0 8200:8200 > ${LOGS}/port_forward_vault.log 2>&1 &

kubectl exec -n vault vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > ${ASSETS}/cluster-keys.json

export VAULT_UNSEAL_KEY=$(cat ${ASSETS}/cluster-keys.json | jq -r ".unseal_keys_b64[]")

# echo $VAULT_UNSEAL_KEY 
# AxB3vSVV7zZSk8oe/x0e2qm8EI2N5lF3z86rZZ0HOe8=

kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
# Key             Value
# ---             -----
# Seal Type       shamir
# Initialized     true
# Sealed          false
# Total Shares    1
# Threshold       1
# Version         1.4.2
# Cluster Name    vault-cluster-07da5f0c
# Cluster ID      164a41f5-1e57-e928-ed89-7fcd11b0b65c
# HA Enabled      false

export VAULT_ADDR=http://localhost:8200
export VAULT_TOKEN=`cat assets/cluster-keys.json | jq -r ".root_token"`

export PATH=$PATH:./bin

## KV configuration

vault secrets enable -path=consul kv-v2
# Success! Enabled the kv-v2 secrets engine at: consul/

vault kv put consul/secret/gossip gossip="$(consul keygen)"
# Key              Value
# ---              -----
# created_time     2022-03-16T18:18:52.389731147Z
# deletion_time    n/a
# destroyed        false
# version          1

vault kv put consul/secret/enterpriselicense key="$(cat ./consul.hclic)"
# Key                Value
# ---                -----
# created_time       2022-03-22T16:25:14.073090874Z
# custom_metadata    <nil>
# deletion_time      n/a
# destroyed          false
# version            1

## PKI configuration

vault secrets enable pki
# Success! Enabled the pki secrets engine at: pki/

vault secrets tune -max-lease-ttl=87600h pki
# Success! Tuned the secrets engine at: pki/

vault write -field=certificate pki/root/generate/internal \
  common_name="dc1.consul" \
  ttl=87600h > ${ASSETS}/consul_ca.crt
# -----BEGIN CERTIFICATE-----
# MIIDMjCCAhqgAwIBAgIUGnHzuETSKLBqYz7CnW9iDdFbGVAwDQYJKoZIhvcNAQEL
# BQAwFTETMBEGA1UEAxMKZGMxLmNvbnN1bDAeFw0yMjAzMTcxMDQwNTlaFw0zMjAz
# MTQxMDQxMjlaMBUxEzARBgNVBAMTCmRjMS5jb25zdWwwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQDPUSYAR+iHHSQlc0qUmWvix3GZIrc+yMg9RZPbaSCH
# ttBd0p71weYXbMjNg8Ob0CY6umEdycXtCGOZBCkBBGPRisMrVoF9RIrWBII9XGbR
# 36bggYaOTtw9FYfVqVCcO1ZilcnRUpBFrtVCDVd3TZXvEPWv7j0cQ0FwqbSur3Db
# VCNYPuCKt/l+6wlTo8yFOMRaxkBDKDGFnDKIV2gHw34xZ5vrqt2Vdeif5HSI3X3r
# +zr6YAdWuwiJP+S4aTXohRinFLqHw1NMjrzbzqb8mRkuchyDfnjZBur5gxj1Z9Xs
# o7fpfmWzFIleOjYHREmHtcjMcu8tti2LuGjJUAVnVg5hAgMBAAGjejB4MA4GA1Ud
# DwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR8hhn7L3Lze5LN
# aYAWszT/oo4C6TAfBgNVHSMEGDAWgBR8hhn7L3Lze5LNaYAWszT/oo4C6TAVBgNV
# HREEDjAMggpkYzEuY29uc3VsMA0GCSqGSIb3DQEBCwUAA4IBAQAddNVes5f4vmO0
# zh03ShJPxH929IXFLs09uwEU3lnCQuiEhEY86x01kvSGqVnSxyBH+Xtn5va2bPCd
# PQsr+9dj6J2eCV1gee6YNtKIEly4NHmYU+3ReexoGLl79guKUvOh1PG1MfHLQQun
# +Y74z3s5YW89rdniWK/KdORPr63p+XQvbiuhZLfveY8BLk55mVlojKMs9HV5YOPh
# znOLQNTJku04vdltNGQ4yRMDswPM2lTtUVdIgzI6S7j3DDK+gawDHLFa90zq87qY
# Qux7KBBlN1VEaRQas4FrvqeRR3FtqFTzn3p+QLpOHXw3te1/6fl5oe4Cch8ZROVB
# 5U3wt2Em
# -----END CERTIFICATE-----

vault write pki/roles/consul-server \
  allowed_domains="dc1.consul,consul-server,consul-server.consul,consul-server.consul.svc" \
  allow_subdomains=true \
  allow_bare_domains=true \
  allow_localhost=true \
  generate_lease=true \
  max_ttl="720h"
# Success! Data written to: pki/roles/consul-server

vault secrets enable -path connect-root pki
# Success! Enabled the pki secrets engine at: connect-root/

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

## Generate policies

vault policy write gossip-policy - <<EOF
path "consul/data/secret/gossip" {
  capabilities = ["read"]
}
EOF
# Success! Uploaded policy: gossip-policy

vault policy write enterpriselicense-policy - <<EOF
path "consul/data/secret/enterpriselicense" {  capabilities = ["read"]}
EOF
# Success! Uploaded policy: enterpriselicense-policy


vault policy write consul-server - <<EOF
path "kv/data/consul-server"
{
  capabilities = ["read"]
}
path "pki/issue/consul-server"
{
  capabilities = ["read","update"]
}
path "pki/cert/ca"
{
  capabilities = ["read"]
}
EOF
# Success! Uploaded policy: consul-server

vault policy write ca-policy - <<EOF
path "pki/cert/ca" {
  capabilities = ["read"]
}
EOF
# Success! Uploaded policy: ca-policy

vault policy write connect - <<EOF
path "connect-root/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
path "connect-intermediate*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "sys/mounts"
{
  capabilities = ["create","update","read","sudo"]
}
path "sys/mounts/*"
{
  capabilities = ["create","update","read","sudo"]
}
path "auth/token/lookup" {
  capabilities = ["create","update"]
}
EOF
# Success! Uploaded policy: connect

### k8s auth roles

vault write auth/kubernetes/role/consul-server \
  bound_service_account_names=consul-server \
  bound_service_account_namespaces=consul \
  policies="gossip-policy,consul-server,connect,enterpriselicense-policy" \
  ttl=24h
# Success! Data written to: auth/kubernetes/role/consul-server


vault write auth/kubernetes/role/consul-client \
  bound_service_account_names=consul-client \
  bound_service_account_namespaces=consul \
  policies="gossip-policy,ca-policy,enterpriselicense-policy" \
  ttl=24h
# Success! Data written to: auth/kubernetes/role/consul-client


## Why namespace consul here?

vault write auth/kubernetes/role/consul-ca \
  bound_service_account_names="*" \
  bound_service_account_namespaces=consul \
  policies=ca-policy \
  ttl=1h
# Success! Data written to: auth/kubernetes/role/consul-ca

# vault write auth/kubernetes/role/server-acl-init \
#   bound_service_account_names=consul-server-acl-init \
#   bound_service_account_namespaces="" \
#   policies="consul-replication-token" \
#   ttl=24h






# kubectl create namespace consul
# namespace/consul created

# kubectl create secret generic consul-ent-license --from-literal="key=$(cat consul.hclic)" -n consul
# error: failed to create secret namespaces "consul" not found
# secret/consul-ent-license created

