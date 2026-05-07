# Deploy PoundCake StackStorm

This repository owns the StackStorm runtime used by PoundCake and the PoundCake-owned StackStorm pack content.

```bash
./bin/install-poundcake-stackstorm.sh
```

Defaults:

- namespace: `stackstorm`
- release: `poundcake-stackstorm`
- chart: local `./helm`
- override directory: `/etc/genestack/helm-configs/poundcake-stackstorm`

After this chart is installed, install PoundCake with its StackStorm adapter pointing at:

```yaml
stackstorm:
  enabled: false
  url: http://stackstorm-api.stackstorm.svc.cluster.local:9101
  authUrl: http://stackstorm-auth.stackstorm.svc.cluster.local:9100
  apiKeySecretName: stackstorm-apikeys
  apiKeySecretKey: st2_api_key
```

The StackStorm bootstrap job creates `stackstorm-apikeys/st2_api_key`. PoundCake imports that key during plugin bootstrap into its encrypted `service_plugin_credentials` row for the `stackstorm` adapter.
