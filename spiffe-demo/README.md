# SPIFFE / SPIRE for the refund agent (GitOps)

> This folder is the GitOps source of the whole refund desk. Start, validate and the project layout are in
> `refund-desk-e2e/README.md` (next to this repo on the Mac): `refund-desk-e2e/scripts/up.sh` then `scripts/validate.sh`.
> Folders here: `apps/` (Argo CD Applications), `spire*/`, `observability/` (OTel collector, Prometheus, Loki, Promtail, Grafana),
> `refund-desk/` (gateway, router, policy, tracing), `refund-services/` (refund-agent, mcp-service, legacy-service, NetworkPolicies), `intruder/`.
> Remove everything: `./down.sh`.

```
Customer ──► router-agent (pod) ──mTLS──► refund-gateway ──http──► refund agent :8500 ─► MCP :8200 ─► refund svc :8100
              id: .../sa/router-agent       checks cert, reads the        (your Mac, unchanged)
              (SVID from SPIRE)             caller's SPIFFE ID, applies
                                            policy: router only, /api/refund*
SPIRE (server + agent) issues an SVID to the router and to the gateway.   GitHub ──► Argo CD ──► the whole cluster side
```

## Ideas in one minute
* **SPIFFE ID**: a workload's name, `spiffe://fde.local/ns/refund-desk/sa/router-agent`.
* **SVID**: the short-lived X.509 certificate that proves the name. SPIRE rotates it; there is no API key.
* **SPIRE** hands an SVID out only after checking where the pod runs (namespace + service account, asked of the kubelet).
* **mTLS**: both sides show certificates. The gateway trusts only certificates signed by SPIRE.
* **Authorization**: the gateway reads the caller's SPIFFE ID from the verified certificate and compares it with the allow-list.

## How it is deployed (GitOps)
`kubectl apply -f argocd/spiffe-demo.yaml` is the only manual step (`./up.sh` also builds the router image).
It is an app-of-apps; Argo CD then creates, in order:

| Application | Path in this repo | What it deploys |
|---|---|---|
| `spire-crds` (wave 0) | `spiffe-demo/spire/crds` | SPIRE CRDs |
| `spire` (wave 1) | `spiffe-demo/spire` | SPIRE server, agent, CSI driver, controller (rendered once from the upstream chart, see `render.sh`) |
| `refund-desk` (wave 2) | `spiffe-demo/refund-desk` | gateway, route, router-agent, policy |
| `intruder` (manual sync) | `spiffe-demo/intruder` | the negative test, run by syncing it |

## Technical walk-through (files in `refund-desk/`)
1. `10-gateway.yaml`: `AgentgatewayParameters{spiffe: {}}` makes the gateway fetch its own SVID and the SPIRE trust bundle from the SPIRE agent socket (mounted by the SPIFFE CSI driver). The HTTPS listener uses it (`tls-certificate-source: SPIFFE`) and therefore requires a client certificate from the same SPIRE.
2. `20-refund-agent-route.yaml`: an `AgentgatewayBackend` points at the Mac (`192.168.5.2:8500`); an `HTTPRoute` sends the listener's traffic to it.
3. `30-router-agent.yaml`: the router runs in the cluster so SPIRE can attest it. A `spiffe-helper` sidecar writes `svid.pem`, `svid_key.pem`, `bundle.pem` into a shared folder and refreshes them on rotation.
4. Router code (`day1-projects/router-agent`): `identity.py` builds an SSL context (our SVID as client cert, trust only the SPIRE bundle); `domains.py` uses it when `ROUTER_SPIFFE_DIR` is set and reloads it when the file changes. Empty setting = old behaviour.
5. `40-authz.yaml`: one CEL rule on the route: `source.subjectAltNames` contains the router's SPIFFE ID **and** the path starts with `/api/refund` (or is `/health`). Two separate expressions would be OR-ed, so it is one `&&`.

## What happens on a request
1. Customer message reaches the router: input guardrails, route to the refund domain.
2. Router opens mTLS to the gateway and presents its SVID.
3. Gateway verifies the chain against the SPIRE bundle, reads the SPIFFE ID, runs the policy.
4. Allowed: forwards plain HTTP to the refund agent. Denied: 403, the agent never sees it.

## Run
```bash
./up.sh      # build router image, register the root Application; Argo CD does the rest
./demo.sh    # readiness, a real refund, prompt injection, and the intruder test
./down.sh    # delete the root Application; Argo CD removes everything
```
Expected: no certificate → TLS refused; router → 200; intruder with a valid but wrong SVID → 403.

## Limits
* The refund agent still listens on the Mac, so anything on your machine can bypass the gateway.
* Gateway to refund agent is plain HTTP (a SPIFFE leg there needs the agent to speak TLS).
* The router checks the gateway's certificate against the SPIRE bundle, not its SPIFFE ID.
* `router-agent:1.0.0` is a local image (like your other charts); the router code change is in the `training` repo, not here.
* Prerequisite outside Git: the agentgateway controller must be running (it was scaled to 0).
