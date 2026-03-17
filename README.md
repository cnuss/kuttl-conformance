# Kubernetes Chainsaw Conformance Tests

Declarative end-to-end tests for core Kubernetes functionality using [Chainsaw](https://kyverno.github.io/chainsaw/) (Kyverno).

## Test Suites

### Pods (8 tests)

| Test | Description |
|------|-------------|
| `pod-lifecycle` | Create, run, and delete a pod |
| `pod-probes` | Liveness, readiness, and startup probes |
| `pod-lifecycle-hooks` | PostStart and preStop container hooks |
| `init-containers` | Sequential init containers with shared volumes |
| `security-context` | runAsUser, readOnlyRootFilesystem, runAsNonRoot |
| `dns-config` | Custom DNS config and dnsPolicy: None |
| `restart-policy` | Never, OnFailure, and Always restart behaviors |
| `resource-requests-limits` | CPU/memory requests and limits, unschedulable pods |

### Workloads (7 tests)

| Test | Description |
|------|-------------|
| `deployment-lifecycle` | Create, scale, and rolling-update a deployment |
| `deployment-strategy` | Recreate and RollingUpdate strategies |
| `replicaset` | Standalone ReplicaSet scaling |
| `statefulset` | Ordered pod creation and stable network identity |
| `daemonset` | Pods scheduled on all nodes |
| `job-completion` | Run a Job to completion |
| `cronjob-scheduling` | CronJob spawns child Jobs |

### Networking (6 tests)

| Test | Description |
|------|-------------|
| `service-clusterip` | ClusterIP service with endpoint verification |
| `service-nodeport` | NodePort service with endpoint verification |
| `headless-service` | Headless service (clusterIP: None) with endpoints |
| `endpoint-slices` | EndpointSlice population for services |
| `network-policy` | NetworkPolicy resource creation |
| `ingress` | Ingress resource acceptance |

### Configuration (6 tests)

| Test | Description |
|------|-------------|
| `configmap-mount` | ConfigMap as env var and volume mount |
| `secret-mount` | Secret mounted into a pod |
| `volume-types` | emptyDir, configMap, secret, downwardAPI, projected |
| `volume-submounts` | subPath mounts, shared emptyDir sidecar pattern |
| `hostpath-volume` | hostPath volume (DirectoryOrCreate) |
| `persistent-volume-claim` | PVC bound to a pod |

### Scheduling (6 tests)

| Test | Description |
|------|-------------|
| `node-selector` | Schedule by node label, verify Pending on mismatch |
| `node-affinity` | Required and preferred node affinity |
| `pod-affinity` | Pod affinity and anti-affinity |
| `taints-tolerations` | Taint blocks scheduling, toleration allows it |
| `priority-class` | PriorityClass with verified priority value |
| `topology-spread` | TopologySpreadConstraints |

### Auth (3 tests)

| Test | Description |
|------|-------------|
| `rbac` | ServiceAccount, Role, RoleBinding access control |
| `clusterrole-binding` | ClusterRole and ClusterRoleBinding |
| `serviceaccount-token` | Token auto-mount, opt-out, and projected tokens |

### Policy (4 tests)

| Test | Description |
|------|-------------|
| `resource-quota` | ResourceQuota enforcement |
| `limit-range` | Default resource limits injected by LimitRange |
| `pod-disruption-budget` | PDB with minAvailable |
| `horizontal-pod-autoscaler` | HPA targeting a deployment |

### API (4 tests)

| Test | Description |
|------|-------------|
| `crd-lifecycle` | CRD creation, CR CRUD, schema validation |
| `finalizers` | Finalizer blocks deletion, removal completes it |
| `labels-annotations` | Label/annotation CRUD, selector queries |
| `namespace-lifecycle` | Create and delete namespaces |

### Observability (2 tests)

| Test | Description |
|------|-------------|
| `pod-logs` | Verify expected log output via kubectl logs |
| `pod-events` | Verify lifecycle events (Scheduled, Pulled, Started) |

## Prerequisites

- `kubectl` configured with cluster access
- [chainsaw](https://kyverno.github.io/chainsaw/) v0.2.14+ — installed automatically by `make install-chainsaw`
- A running Kubernetes cluster (Kind, k3s, minikube, etc.)

## Running Tests

Run all tests (creates a Kind cluster if needed):

```bash
make test
```

Run a single suite:

```bash
make test SUITE=pods
```

Run a single test:

```bash
make test SUITE=pods WHAT=pod-lifecycle
```

Run against an existing cluster:

```bash
make test KIND=false
```

## Design Principles

- **Self-contained**: Each test uses Chainsaw's automatic namespace management. No cross-test dependencies.
- **Lightweight images**: Tests use `busybox:1.37` and `nginx:1.27`.
- **Subset assertions**: Only fields that matter are asserted. No over-specification.
- **Declarative first**: Script assertions only where YAML matching can't express the check.
- **Realistic timeouts**: 60s default; individual steps override where needed.
- **Kind-compatible**: Every test passes on a standard Kind cluster with no special configuration.
- **Portable**: No assumptions about cluster domain (`svc.cluster.local`).

## License

[MIT](LICENSE)
