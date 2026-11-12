#!/usr/bin/env bash
# GitOps: everything is deployed by Argo CD from GitHub (spiffe-demo/ in the repo). This only builds the router image
# (local image, never pulled) and registers the three Applications.   ./up.sh  then  ./demo.sh   (remove: ./down.sh)
# Needs the refund agent running on the Mac (:8500): day-3/langgraph_console/start-all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
docker build -q -t router-agent:spiffe ../projects/training/day1-projects/router-agent
kubectl scale deploy/agentgateway deploy/agentgateway-proxy -n agentgateway-system --replicas=1   # the cluster was scaled to 0
kubectl apply -f argocd/spire-crds.yaml -f argocd/spire.yaml -f argocd/refund-desk.yaml
echo "Watch: kubectl get applications -n argocd   (spire-crds, spire, refund-desk should become Synced/Healthy)"
