#!/usr/bin/env zsh 
set -e

echo "Deleting any kind clusters..."
kind delete clusters --all

echo "Setting kernel parameter... net/netfilter/nf_conntrack_max"
sudo sysctl -w net.netfilter.nf_conntrack_max=${1:-393216}

echo "Installing kubernetes cluster..."
kind create cluster --name kube-lab --config multi-node-cluster-config.yaml

echo "Setting cluster info context..."
kubectl cluster-info --context kube-istio-lab

for pod in $(kubectl get pods -n kube-system -o jsonpath='{.items[0].metadata.name}'); do
    while [[ $(kubectl get pods $pod -n kube-system -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do 
        sleep 3
        echo "Waiting for $pod to be ready."
    done
done

echo "Installing shpod kubernetes objects/pods... and enabling sidecar injection on shpod namespace..."
kubectl apply -f shpod-namespace.yaml
kubectl apply -f shpod.yaml
