# Deployment and configuration concerns

Load when the diff touches environment variables, config loading, Dockerfiles, infrastructure-as-code, CI, or process startup and shutdown.
load-when: `Dockerfile*`, `**/Dockerfile*`, `docker-compose*`, `**/docker-compose*`, `**/*.tf`, `**/*.tfvars`, `.github/workflows/**`, `**/.env*`, `**/*.env`, `**/config/**`, `**/*.config.*`, `**/k8s/**`, `**/helm/**`, `**/infra/**`, `**/deploy/**`, `Procfile`, `**/main.*`, `**/server.*`, `**/bootstrap.*`

## Correctness

- **Config value never reaches its consumer** (`correctness/dead-config-field`, default bug): A config field or environment variable is useless if the code that sets the behavior hardcodes the value, or runs in a context (sandboxed worker, separate process) that cannot read the config. The variable silently has no effect. Wire it through or remove it.
  - look-for: a new env-backed field with no read path to the code it claims to control, while that code uses a literal.
  - triggers: `env`, `environ`, `config`, `getenv`

- **Empty-string default passed to a client** (`correctness/empty-config-default`, default bug): Defaulting a missing variable to `''` and handing it to an SDK constructor often throws at startup or fails far from the cause. Check for missing values explicitly and fail with a clear message or skip the feature.
  - look-for: `process.env.X ?? ''` or similar passed straight to a client factory.
  - triggers: `?? ''`, `?? ""`, `|| ''`, `|| ""`, `, '')`, `, "")`, `:-}`

- **Buffered data lost on shutdown** (`correctness/no-shutdown-flush`, default bug): Batching processors for telemetry, logs, or queues drop their buffer on every deploy or eviction unless a termination handler flushes them.
  - look-for: module-level batching providers or buffers with no SIGTERM or exit handler calling their flush or shutdown.
  - triggers: `batch`, `buffer`, `Processor`, `Exporter`, `flush`, `shutdown`, `SIGTERM`

## Architecture

- **New variable not provisioned** (`architecture/unprovisioned-env-var`, default issue): A new environment variable must be added to every environment's config, deployment definitions, and the example env file before merge, or the next deploy breaks or strips it.
  - look-for: new env reads with no matching change to deployment config or the env template.
  - triggers: `env`, `environ`, `config.get`

- **Environment config not parameterized** (`architecture/unparameterized-env-config`, default issue): Tiers, scaling, notification targets, and provider settings usually differ between environments; hardcoding one value for all, or adding a setting to one environment but not its siblings, causes surprises in production.
  - look-for: literals in infrastructure definitions that should vary by environment; a setting present in one environment file only.
  - applies-to: `**/*.tf`, `**/*.tfvars`, `**/*.hcl`, `**/*.yaml`, `**/*.yml`, `**/*.json`, `**/*.toml`, `**/.env*`, `**/*.env`, `**/infra/**`, `**/deploy/**`, `**/k8s/**`, `**/helm/**`, `**/config/**`, `Dockerfile*`, `**/Dockerfile*`, `docker-compose*`, `**/docker-compose*`

- **Unpinned image or system dependency** (`architecture/unpinned-dependency`, default issue): Base images, installed tools, and system packages whose compatibility is coupled to app libraries (a browser with its automation library) must be pinned so builds are reproducible and upstream updates do not break them silently.
  - look-for: `FROM` or package-install lines without an exact version; `latest` tags.
  - applies-to: `Dockerfile*`, `**/Dockerfile*`, `**/*.dockerfile`, `docker-compose*`, `**/docker-compose*`, `**/*.yaml`, `**/*.yml`, `**/*.sh`, `**/*.tf`, `.github/workflows/**`
  - triggers: `FROM `, `image`, `latest`, `install`, `add `, `uses:`

- **Config wired at the entrypoint** (`architecture/config-at-entrypoint`, default nit): Module configuration assembled inline in the application entrypoint is hard to find and test. Put it in a dedicated config unit owned by the module that uses it.
  - look-for: env parsing or module options added to the main bootstrap file.
  - applies-to: `**/main.*`, `**/index.*`, `**/app.*`, `**/server.*`, `**/bootstrap.*`, `**/app.module.*`, `**/program.*`, `**/__main__.py`, `**/wsgi.py`, `**/asgi.py`, `**/cmd/**`
  - triggers: `env`, `config`, `options`, `forRoot(`, `register(`

## Style

- **Orphaned or duplicate variable** (`style/orphaned-env-var`, default nit): Declared variables that nothing reads, and two names for the same secret, confuse operators. Remove unused ones and reuse the existing key.
  - look-for: env declarations with no read site; a new variable holding a value an existing one already provides.
