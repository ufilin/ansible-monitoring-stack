# Ansible Monitoring Stack

Lab-ready monitoring stack for Linux hosts: **Prometheus + Grafana + Alertmanager + node_exporter + blackbox_exporter**, deployed either with a single `docker compose up` or with Ansible.

The goal of this repo is to keep one reproducible place for the monitoring setup I use in my own lab and to show the workflow end to end: configuration as code, alert rules, dashboards as code and CI that lints all of it.

## What is inside

```
prometheus/          scrape config + alert rules (host and probe)
alertmanager/        routing and grouping
blackbox/            HTTP/ICMP probing modules
grafana/             provisioned datasource + dashboard as JSON
ansible/             playbook and roles: docker, monitoring
.github/workflows/   CI: yamllint, ansible-lint, promtool, compose config
```

## Quick start

```bash
git clone https://github.com/ufilin/ansible-monitoring-stack.git
cd ansible-monitoring-stack
docker compose up -d
```

Then:

| Service | URL | Credentials |
|---|---|---|
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3000 | admin / admin (change on first login) |
| Alertmanager | http://localhost:9093 | — |

Prometheus scrapes itself, `node_exporter` and `blackbox_exporter`. The example probe target is `https://example.com` — edit `prometheus/prometheus.yml` to point at your own endpoints.

## Alerts

Rules live in `prometheus/alerts/`:

| Alert | Expression | For |
|---|---|---|
| `InstanceDown` | `up == 0` | 1m |
| `HighCpuUsage` | CPU busy > 85% | 10m |
| `DiskWillFillIn4Hours` | predicted fill from `predict_linear` | 10m |
| `MemoryPressure` | available memory < 10% | 10m |
| `ProbeFailed` | `probe_success == 0` | 2m |
| `SSLCertExpiringSoon` | cert expires in < 14 days | 5m |

Alertmanager groups by `alertname` and `instance` and sends everything to a placeholder receiver — plug in your own webhook, Telegram bot or email in `alertmanager/alertmanager.yml`.

## Deploy with Ansible

```bash
cd ansible
cp inventory.example.ini inventory.ini   # put your hosts here
ansible-playbook -i inventory.ini playbook.yml --check
ansible-playbook -i inventory.ini playbook.yml
```

The `docker` role installs Docker from the official repository, the `monitoring` role creates `/opt/monitoring`, templates the compose file and brings the stack up. Everything is idempotent; `--check` shows the diff before anything changes.

## CI

Every push runs:

- `yamllint` over all YAML;
- `ansible-lint` over the playbook and roles;
- `promtool check config` and `promtool check rules`;
- `docker compose config` to make sure the stack still renders.

## Notes and limitations

- This is a **lab / reference** setup, not a hardened production deployment. No TLS termination, no authentication on Prometheus and Alertmanager, single node.
- Grafana admin password is set through `GF_SECURITY_ADMIN_PASSWORD` in `docker-compose.yml` — override it in your own copy.
- Retention defaults to 15 days; adjust `--storage.tsdb.retention.time` for real use.

## License

MIT
