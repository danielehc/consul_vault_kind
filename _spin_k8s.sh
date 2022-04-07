#!/usr/bin/env bash

CLUSTER="dc1"
ASSETS="./assets"
LOGS="./logs"


clean_env() {
    kind delete cluster --name ${CLUSTER}
}

## Check Parameters
if   [ "$1" == "clean" ]; then
  clean_env
  exit 0
fi


## Clean environment
echo "Cleaning Environment"
clean_env

cat > ${ASSETS}/kind-config.yaml <<EOF
# three node (two workers) cluster config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF


kind create cluster --name ${CLUSTER} --config ${ASSETS}/kind-config.yaml

kubectl cluster-info --context kind-${CLUSTER}

# helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# helm install dashboard kubernetes-dashboard/kubernetes-dashboard -n kubernetes-dashboard --create-namespace

# tee ${ASSETS}/service-account.yaml > /dev/null << EOF
# # service-account.yaml
# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: admin-user
#   namespace: kubernetes-dashboard

# ---

# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: admin-user
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
# - kind: ServiceAccount
#   name: admin-user
#   namespace: kubernetes-dashboard
# EOF

# kubectl apply -f ${ASSETS}/service-account.yaml

# kubectl describe secret  `kubectl describe serviceaccount admin-user -n kubernetes-dashboard | grep Tokens | awk '{print $2}'` -n kubernetes-dashboard


# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
# kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
# # docker network inspect -f '{{.IPAM.Config}}' kind
# # kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml
# kubectl apply -f ${ASSETS}/metallb-configmap.yaml





