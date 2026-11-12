# SPIFFE / SPIRE for the refund agent

## Architecture

```
                         Kubernetes (Rancher Desktop)                                   your Mac
 ┌──────────────────────────────────────────────────────────────────────────┐   ┌─────────────────────────┐
 │  SPIRE server + agent  ── issues short-lived X.509-SVIDs (trust domain fde.local)   │   │                         │
 │         │ Workload API (unix socket, mounted by the SPIFFE CSI driver)      │   │                         │
 │         ▼                                                                  │   │  refund agent  :8500    │
 │  router-agent pod            refund-gateway (agentgateway)                  │   │   └─ MCP :8200          │
 │  guardrails → route          1 serves its own SVID, demands a client cert   │   │       └─ refund svc     │
 │  id: .../sa/router-agent ──mTLS──► 2 reads caller id from the cert  ────────┼──►│          :8100          │
 │  (spiffe-helper keeps SVID   3 policy: only router-agent, only /api/refund  │ http│                         │
 │   fresh in /spiffe)          4 forwards to the Mac (192.168.5.2:8500)       │   │                         │
 └──────────────────────────────────────────────────────────────────────────┘   └─────────────────────────┘
```

* **SPIFFE ID** = the name of a workload: `spiffe://fde.local/ns/refund-desk/sa/router-agent`.
* **SVID** = the certificate that proves it (X.509, one hour, rotated by SPIRE). No password, no API key to leak.
* **SPIRE** hands out SVIDs after checking *where* the workload runs (namespace + service account, via the kubelet).
* **Gateway** is the policy point: it verifies the caller's certificate and authorizes by SPIFFE ID.
* The refund agent itself is **unchanged**; it just sits behind the gateway.

## What was done, step by step

1. **SPIRE installed** (`spire-values.yaml`, Helm, namespace `spire-mgmt`). Its default registration gives every pod `spiffe://fde.local/ns/<ns>/sa/<sa>`.
2. **Removed** the earlier throw-away demo (orders-agent, rogue-agent pods, legacy-service route and policy, namespace `spiffe-demo`).
3. **Router given an identity.** In `day1-projects/router-agent`: new `identity.py` (loads the SVID as mTLS client certificate, trusts only the SPIRE bundle), `domains.py` (calls the refund agent with it, reloads when SPIRE rotates it), setting `ROUTER_SPIFFE_DIR`, a `Dockerfile`. With the setting empty the router behaves exactly as before; its 33 tests pass.
4. **Router moved into the cluster** (`30-router-agent.yaml`) so SPIRE can attest it; `spiffe-helper` sidecar writes `svid.pem`, `svid_key.pem`, `bundle.pem`.
5. **Gateway** (`10-gateway.yaml`): `spiffe: {}` makes it fetch its own SVID; the HTTPS listener uses it (`tls-certificate-source: SPIFFE`) and requires a client certificate from the same SPIRE.
6. **Route to the Mac** (`20-refund-agent-route.yaml`): an `AgentgatewayBackend` pointing at your Mac, so the refund agent is not moved.
7. **Policy** (`40-authz.yaml`): `source.subjectAltNames` (the caller's SPIFFE ID) must be the router's, and the path must be `/api/refund*` or `/health`.

## Run

```bash
./up.sh      # first time (needs the refund agent running on :8500)
./demo.sh    # the four checks below
./down.sh    # remove everything
```

| Check | Result |
|---|---|
| Router `/ready` (calls the agent through the gateway) | 200 |
| Refund request, full path | `answered`, gateway logs `/api/refund 200` |
| Prompt injection | blocked by the router, gateway never sees it |
| Intruder pod, no certificate | TLS handshake refused |
| Intruder pod, valid SVID but not the router | 403 `authorization failed` |

## Limits (honest list)
* The refund agent still listens on the Mac's `:8500`, so anything on your machine can bypass the gateway. In a real cluster it would be a pod with a NetworkPolicy allowing only the gateway.
* Gateway to refund agent is plain HTTP; the gateway-to-backend SPIFFE leg (`backend.tls.certificateSource: SPIFFE`) needs the agent to speak TLS.
* The router checks the gateway's certificate against the SPIRE bundle but not its SPIFFE ID (Python `ssl` cannot match URI SANs).
* The router in the cluster has no Langfuse; the router on your Mac (:8600) still runs untouched.
* The cluster was scaled to 0; `up.sh` scales the gateway back to 1.
