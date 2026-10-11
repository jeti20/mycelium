# SLO decision record

Why each SLI looks the way it does, why the objectives are what they are, and what each one
deliberately does **not** measure. SLO specs: [`slos/`](../slos) → generated rules:
[`prometheus/rules/slo/`](../prometheus/rules/slo) → building blocks:
[`prometheus/rules/sli.yml`](../prometheus/rules/sli.yml).

## Who are the users?

| User | What they need | Covered by |
|---|---|---|
| Someone opening the dashboards | current data, panels that load fast | platform `dashboard-freshness`, `dashboard-latency` |
| The on-call person | alerts that actually arrive | platform `alert-delivery`, Watchdog + heartbeat check |
| The pipeline itself | telemetry that isn't silently dropped | platform `telemetry-ingestion` |
| Mycelium as a consumer of public APIs | upstreams that answer, quickly, with fresh and correct data | per-provider `availability`, `latency`, `freshness`, `correctness` |

## Who gets woken up

**Only for what we own.** The four public APIs are dependencies run by other people. Their SLOs
exist to *inform*: to quantify how reliable each dependency is, to make "is it them or us?" a
one-glance question, and to drive conversations (or a change of provider), not pagers.

| | Fast burn (14.4× / 6×) | Slow burn (3× / 1×) |
|---|---|---|
| `tier=platform` (Mycelium) | **page** → #oncall, 24/7 | ticket → #tickets, working hours |
| `tier=upstream` (providers) | ticket → #tickets, working hours | `none` → recorded, visible, nobody notified |

Sloth's own tier label (`sloth_severity`) is kept, so Alertmanager can still inhibit the slow tier
while the fast tier fires, independent of our routing severity.

## Three flavours of SLI

| Flavour | How it counts | Used for | Trade-off |
|---|---|---|---|
| **Event-based** | raw samples / counter increments in the window (`count_over_time`, `sum_over_time`, `rate`) | availability, correctness, alert delivery, telemetry ingestion, dashboard latency | exact, but needs one data point per event — hence `httpcheck.success` (below) |
| **Time-based** | fraction of rule evaluations (every 30 s) where a condition held | freshness (provider and dashboard) | "how long was it broken", not "how many requests failed" — the right question for staleness |
| **Resampled** | a per-probe boolean recorded every 30 s, then averaged | probe latency | each probe is counted ~4× uniformly, so the ratio is right; edge effects at window borders |

## Provider SLIs

### availability — event-based, synthetic

*Good event:* a synthetic probe (OpenTelemetry `http_check`, every 2 min) received a 2xx.

- **Why synthetic, not the real consumer's scrapes?** Wikimedia, GBIF and Mastodon are scraped
  every 10 min: 144 events a day per target. With a 99 % objective a single failed scrape burns
  more than 2 % of a month's budget, and the 5-minute alert window often contains no scrape at all. The SRE Workbook's answer for low-traffic services
  is synthetic traffic: 720 uniform events/day per provider. Consumer-side failures are still
  caught by `ConsumerScrapesFailing`.
- **Why `httpcheck.success` and not `httpcheck.status`?** `httpcheck.status` produces one series
  per status code. After a failure the previous `code="200"` series keeps its last value for the
  5-minute lookback (OTLP pushes carry no staleness markers), so `max()` across series hides the
  outage. An OTTL `copy_metric` in the collector creates `httpcheck.success`: one series, one point
  per probe, 1 or 0.
- Objectives: 99.5 % (iNaturalist, Wikimedia, Mastodon), 99 % (GBIF — occurrence search is heavy).

### latency — resampled

*Good:* the probe answered 2xx **and** within the provider's threshold
(`provider:latency_threshold:ms`). A failed request is never "fast".

| Provider | Threshold | Observed (first day) | Why |
|---|---|---|---|
| iNaturalist | 1500 ms | ~650–900 ms total, of which ~330 ms is the TLS handshake to a US origin | headroom ≈ 2× p95; it's a polling consumer, nobody waits interactively |
| Wikimedia | 1000 ms | 60–400 ms (CDN edge) | |
| Mastodon | 1000 ms | 60–620 ms | |
| GBIF | 1000 ms | 60–220 ms | objective 98 %: occasional slow occurrence searches are normal |

Each probe opens a new connection, so DNS + TCP + TLS are part of every measurement. That's
intentional: it is what json-exporter experiences too.

### freshness — time-based

| Provider | "Fresh" means | Why |
|---|---|---|
| iNaturalist | the id of the newest fungus observation **worldwide** changed within 20 min | ids only grow; worldwide so that a quiet night in Poland isn't "stale" |
| Wikimedia | the newest published day (max over all articles) ≥ the day before yesterday | daily data with publication lag; `max()` not `min()` — see below |
| Mastodon | every tag's newest day is today (UTC), 30 min grace after midnight | the API's history always starts with today |
| GBIF | — (no SLO) | re-indexed in weekly batches; "unchanged for days" is normal |

Missing data is not fresh data: every freshness rule ends with `or on () vector(0)`. Except right
after a start: for 20 minutes after Prometheus (re)starts the freshness SLIs emit **no samples**
(`platform:prometheus_uptime:seconds > 1200`). Without that warm-up the very first
`docker compose up` paged — no data yet looked exactly like stale data.

**Measure the provider, not yourself.** Provider freshness is observed through our own collection
path (collector → json-exporter). A game day showed that stopping *our* json-exporter made
iNaturalist look stale and burned *its* budget. Provider freshness SLIs therefore also require
`platform:collection_path_up:bool == 1`; our own outage is covered by the platform's
dashboard-freshness SLO instead.

**The `min()` mistake.** The first version required *every* Wikipedia article to have data up to
the cut-off. The page views API omits days with zero views, so a quiet article (a redirect page
had ~0 views a day) looked days behind while the dataset was perfectly fresh. Freshness is a
property of the dataset → `max()`. A unit test covers it.

**Date math in PromQL.** Wikimedia timestamps look like `2026101000`. The cut-off is built in the
same format: `year(vector(time() - 2*86400)) * 1e6 + month(...) * 1e4 + day_of_month(...) * 100`.
promtool tests start at 1970-01-01, so the test asserts `1970010400` at day 5 — readable.

### correctness — event-based

*Good event:* one gjson validation in the probe passed. Examples: the newest observation of a
fungi query **is a fungus** (`results.0.taxon.iconic_taxon_name == "Fungi"`) and is in Poland; the
Wikimedia response is for `pl.wikipedia` and counts human (`user`) traffic only; a Mastodon tag
history has exactly 7 days. 99.9 %: a broken contract silently corrupts every downstream panel.

## Platform SLIs

| SLO | Objective | SLI | Notes |
|---|---|---|---|
| dashboard-latency | 99 % < 2 s | `histogram_fraction(0, 2, …)` over Grafana's `HTTP POST /api/ds/query` server spans (native histogram from the span_metrics connector) | 2 s is a power of two → always an exact bucket boundary in exponential histograms; windows without requests are dropped, not NaN |
| dashboard-freshness | 99.5 % | newest stored `inat_observations{scope="fungi-pl"}` sample < 10 min old | subquery finds the real sample timestamp even beyond the 5-min lookback |
| alert-delivery | 99.9 % | failed ÷ total e-mail notifications (Alertmanager counters) | NaN guard; black-box twin: Mailpit's accepted counter + `AlertPipelineHeartbeatMissing` |
| telemetry-ingestion | 99.9 % | failed ÷ (sent + failed) metric points of `otlp_http/prometheus` | the failed counter only exists after the first failure → `or vector(0)` |

### The NaN guard

A plain `failed / total` over a 5-minute window with no e-mails is `0/0 = NaN`. Sloth computes the
30-day SLI as the average of all 5-minute ratios, and **one NaN sample turns the 30-day average
into NaN for a month**. Every ratio that can have an empty denominator is therefore written as
`(ratio) and on () (total > 0)`: no events → no sample → nothing to average. Unit-tested.

## Known weaknesses (accepted)

- Sloth's 30-day SLI is the mean of 5-minute ratios, not events over 30 days. With uniform probes
  that's the same thing; for bursty traffic (dashboard requests) quiet periods weigh as much as
  busy ones.
- Fast-burn short windows (5 m) are evaluated on 2–3 probes. A single failed probe is 33–50 %
  errors in that window; the long window (1 h, 30 probes) keeps that from paging on its own.
- Time-based freshness is sampled every 30 s; a 20-second gap is invisible. Nobody cares.
- Fresh installs: 30-day windows contain only minutes of data, so one bad sample moves the budget
  a lot. Numbers stabilise after a few days.
