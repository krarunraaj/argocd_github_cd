#!/usr/bin/env bash
# GitOps: Argo CD deploys everything from GitHub. This builds the router image (a local image, like your other charts use)
# and registers the one root Application.   ./up.sh  then  ./demo.sh   (remove: ./down.sh)
# Prerequisite: the refund agent on the Mac (:8500): day-3/langgraph_console/start-all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
docker build -q -t router-agent:1.0.0 ../projects/training/day1-projects/router-agent
kubectl apply -f argocd/spiffe-demo.yaml
echo "Watch: kubectl get applications -n argocd"
