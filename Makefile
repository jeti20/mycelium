# Shortcuts for Linux/macOS/CI. On Windows run the same `docker compose ...`
# commands directly (in Git Bash prefix them with MSYS_NO_PATHCONV=1).
COMPOSE := docker compose
-include .env
GF_USER ?= $(or $(GF_SECURITY_ADMIN_USER),admin)
GF_PASS ?= $(or $(GF_SECURITY_ADMIN_PASSWORD),admin)
TESTS := tests/sli_test.yml tests/slo_test.yml tests/forest_test.yml tests/platform_test.yml

.PHONY: up down logs slo check validate test lint routes drift screenshots

up:          ## start the stack
	$(COMPOSE) up -d

down:        ## stop the stack (keeps data volumes)
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=100

slo:         ## slos/*.yml -> prometheus/rules/slo/*.yml (Sloth), then reload Prometheus
	$(COMPOSE) run --rm sloth-validate
	$(COMPOSE) run --rm sloth-generate
	-curl -s -X POST http://127.0.0.1:9091/-/reload

check: validate lint test routes drift   ## everything CI runs

validate:    ## configs of every component
	$(COMPOSE) config --quiet
	$(COMPOSE) run --rm otelcol-validate
	$(COMPOSE) run --rm promtool check config /etc/prometheus/prometheus.yml
	$(COMPOSE) run --rm amtool
	$(COMPOSE) run --rm loki-validate
	$(COMPOSE) run --rm sloth-validate

test:        ## promtool unit tests (SLIs, burn-rate alerts, domain rules, platform alerts)
	$(COMPOSE) run --rm promtool test rules $(TESTS)

lint:        ## PromQL lint (Cloudflare pint)
	$(COMPOSE) run --rm pint

routes:      ## Alertmanager routing tests (alertmanager/routing-tests.txt)
	$(COMPOSE) run --rm amtool-routes

drift:       ## generated SLO rules must match slos/*.yml
	$(COMPOSE) run --rm sloth-generate
	git diff --exit-code -- prometheus/rules/slo

screenshots: ## render dashboards to docs/img with grafana-image-renderer
	for d in myc-home/mycelium:1650 myc-forest/forest:2350 myc-interest/interest:1250 \
	         myc-slo/slo:2650 myc-platform/platform:3150; do \
	  uid=$${d%%/*}; path=$${d%%:*}; h=$${d##*:}; \
	  curl -sf -u "$(GF_USER):$(GF_PASS)" -o docs/img/$$uid.png \
	    "http://127.0.0.1:3030/render/d/$$path?width=1600&height=$$h&kiosk=true&theme=dark&timeout=180"; \
	done
