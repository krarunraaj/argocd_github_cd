#!/usr/bin/env bash
# An intruder pod: a perfectly valid SPIRE identity (rogue-agent), but not the router. Runs once, then is deleted.
kubectl apply -f - >/dev/null <<YAML
apiVersion: v1
kind: ServiceAccount
metadata: {name: rogue-agent, namespace: refund-desk}
---
apiVersion: v1
kind: Pod
metadata: {name: rogue-agent, namespace: refund-desk}
spec:
  serviceAccountName: rogue-agent
  restartPolicy: OnFailure   # the SPIRE entry for a new pod takes a few seconds to appear
  securityContext: {runAsUser: 0}
  initContainers:
    - name: fetch-svid
      image: ghcr.io/spiffe/spire-agent:1.15.5
      command: ["/opt/spire/bin/spire-agent"]
      args: ["api","fetch","x509","-socketPath","/spiffe-workload-api/spire-agent.sock","-write","/certs"]
      volumeMounts: [{name: spiffe, mountPath: /spiffe-workload-api, readOnly: true}, {name: certs, mountPath: /certs}]
  containers:
    - name: curl
      image: curlimages/curl:8.11.1
      command: ["sleep","120"]
      volumeMounts: [{name: certs, mountPath: /certs}]
  volumes:
    - {name: certs, emptyDir: {}}
    - {name: spiffe, csi: {driver: csi.spiffe.io, readOnly: true}}
YAML
kubectl wait --for=condition=Ready pod/rogue-agent -n refund-desk --timeout=120s >/dev/null
G=https://refund-gateway.refund-desk.svc.cluster.local:7443
c() { kubectl exec -n refund-desk rogue-agent -c curl -- curl -sS -m 8 -k -o /dev/null -w '   -> HTTP %{http_code}\n' "$@" 2>&1 | grep -v terminated; }
echo "a) no certificate:";                       c $G/health
echo "b) rogue-agent SVID, refund path:";        c --cert /certs/svid.0.pem --key /certs/svid.0.key -X POST -H 'content-type: application/json' -d '{}' $G/api/refund
kubectl delete pod/rogue-agent sa/rogue-agent -n refund-desk --wait=false >/dev/null
