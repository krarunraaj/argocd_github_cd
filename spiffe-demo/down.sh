#!/usr/bin/env bash
# Deleting the Applications makes Argo CD remove everything it deployed (auto-prune). Nothing else is touched.
cd "$(dirname "$0")/.."
kubectl delete -f argocd/refund-desk.yaml -f argocd/spire.yaml -f argocd/spire-crds.yaml --ignore-not-found
