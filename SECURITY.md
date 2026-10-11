# Security

Mycelium is a **local demo / portfolio project**. Its defaults trade security for convenience, on
the assumption that only you can reach it.

| Component | Default | Why it matters |
|---|---|---|
| All published ports | bound to `127.0.0.1` (`BIND_ADDR`) | nothing is reachable from your LAN or the internet |
| Grafana | anonymous **Editor**, admin password `admin` unless set in `.env` | anyone who can reach port 3030 can change dashboards |
| Prometheus | `--web.enable-lifecycle`, OTLP receiver, no auth | can be reloaded/shut down and written to |
| Alertmanager, Mailpit, Sloth UI, collector zPages | no authentication | silences, e-mails and pipeline internals are open |
| OpenTelemetry Collector | runs as root and mounts `/var/lib/docker/containers` **read-only** | it can read every container's logs on the host |
| Grafana image renderer | shared token `GF_RENDERER_TOKEN` | change it if anything else runs on the Docker network |

**Before exposing any of it** (VPS, `BIND_ADDR=0.0.0.0`, port forwarding):

1. set `GF_SECURITY_ADMIN_PASSWORD` and `GF_RENDERER_TOKEN` in `.env`, and `GF_ANONYMOUS_ROLE=Viewer`
   (or `GF_ANONYMOUS_ENABLED=false`),
2. put Grafana behind a reverse proxy with TLS and authentication, and don't publish the
   Prometheus/Alertmanager/Mailpit/Sloth/zPages ports at all,
3. replace Mailpit with a real SMTP relay (credentials in a mounted secret, not in Git),
4. restrict the collector's log collection to the containers you need.

No secrets are stored in this repository. `.env` is git-ignored, and all data sources are public
APIs that need no keys. The User-Agent sent to the APIs identifies the project; if you fork it,
change the contact URL in `json-exporter/config.yml` and `otel-collector/config.yaml`.

## Reporting

Found a problem? Please open a GitHub issue. For anything sensitive, use a private
[security advisory](https://docs.github.com/en/code-security/security-advisories) on the repository.
