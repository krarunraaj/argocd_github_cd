#!/usr/bin/env bash
# How spire/ was produced: the upstream SPIRE charts rendered once to plain YAML, so Argo CD deploys it from GitHub
# (no helm install anywhere). Helm hooks and the chart test pod are dropped: they only flip the controller-manager
# webhook to failurePolicy=Fail and manage upgrades. Re-run to bump versions, review the diff, push.
set -euo pipefail
cd "$(dirname "$0")"
helm repo add spiffe https://spiffe.github.io/helm-charts-hardened/ >/dev/null 2>&1 || true
helm repo update spiffe >/dev/null
helm template spire-crds spiffe/spire-crds -n spire-mgmt > spire/crds/spire-crds.yaml
helm template spire spiffe/spire -n spire-mgmt -f spire-values.yaml | python3 -c '
import sys
docs = sys.stdin.read().split("\n---\n")
print("\n---\n".join(d for d in docs if "helm.sh/hook" not in d and "templates/tests/" not in d))' > spire/spire.yaml
