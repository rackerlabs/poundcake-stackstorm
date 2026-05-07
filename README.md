# poundcake-stackstorm

Standalone Helm chart and StackStorm pack content for PoundCake.

This repo owns:

- StackStorm runtime deployment for PoundCake
- StackStorm startup/bootstrap jobs
- generated ST2 API key secret export
- PoundCake-owned StackStorm actions and workflows under `packs/poundcake`
- tested alert-to-workflow profile metadata in `packs/poundcake/poundcake_profiles.json`

Install locally:

```bash
./bin/install-poundcake-stackstorm.sh
```

See [docs/DEPLOY.md](docs/DEPLOY.md) for the PoundCake wiring values.
