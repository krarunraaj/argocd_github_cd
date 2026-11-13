#!/usr/bin/env bash
# Deleting the root Application removes the child Applications and everything they deployed.
cd "$(dirname "$0")/.."
kubectl delete -f argocd/spiffe-demo.yaml --ignore-not-found
