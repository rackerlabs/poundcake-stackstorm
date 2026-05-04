# Helm Devstack

These helpers create a local kind cluster for PoundCake StackStorm chart work.
The default cluster has one control-plane node and three worker nodes.

## Create

```bash
helm/devstack/create.sh
```

Defaults:

- kind cluster: `poundcake-stackstorm`
- Kubernetes context: `kind-poundcake-stackstorm`
- namespace: `poundcake-stackstorm`
- Helm release: `poundcake-stackstorm`
- chart: `helm`
- values: `helm/devstack/values/stackstorm-kind.yaml`

## Useful Overrides

```bash
INSTALL_CHART=false helm/devstack/create.sh
VALUES_FILE=helm/devstack/values/stackstorm-kind.yaml helm/devstack/create.sh
HELM_EXTRA_ARGS="--set stackstormServices.web.enabled=false" helm/devstack/create.sh
```

## Destroy

```bash
helm/devstack/destroy.sh
```

By default this uninstalls the Helm release and namespace, but leaves the kind
cluster in place. Set `DELETE_CLUSTER=true` to remove the cluster too.

## Port Forward

```bash
helm/devstack/port-forward.sh start
helm/devstack/port-forward.sh status
helm/devstack/port-forward.sh stop
```

The helper forwards:

- StackStorm API: `http://127.0.0.1:9101`
- StackStorm Auth: `http://127.0.0.1:9100`
- StackStorm Stream: `http://127.0.0.1:9102`
- StackStorm Web: `http://127.0.0.1:8080`

It stores pid/log files under `/tmp/poundcake-stackstorm-helm-devstack`.
