# Error budget policy

An SLO without consequences is a wish. This policy says what happens when budgets run low. It is
written for a one-person project, but every step maps onto a team process.

## Scope

All SLOs in [`slos/`](../slos), 30-day rolling windows. Budget remaining is shown per SLO on the
SLO dashboard (`slo:period_error_budget_remaining:ratio`).

## Platform SLOs (tier=platform) — we own them

| Budget left | State | What happens |
|---|---|---|
| > 50 % | healthy | Ship features, experiment, upgrade components freely. |
| 25–50 % | caution | Upgrades only with a rollback plan. Check the burn-rate panels weekly. |
| 0–25 % | freeze | No new dashboards/sources/component upgrades. Work only on reliability: the top contributor to the burn gets fixed first. |
| < 0 % | violated | Freeze continues until the budget is positive again. Write a short incident review (what burned it, why it wasn't caught earlier, what changes). |

A page (`severity=page`) always gets a response, regardless of budget. Changes that caused a burn
are reverted first and analysed second.

## Provider SLOs (tier=upstream) — we depend on them

We can't freeze someone else's deployments. Budgets here trigger *decisions on our side*:

| Situation | Action |
|---|---|
| Budget < 25 % for one provider | Check whether our usage is the cause (rate limiting, User-Agent, timeouts). Increase polling intervals if in doubt. |
| Budget violated two windows in a row | Re-evaluate the dependency: cache more aggressively, find an alternative source, or document the degraded feature on the dashboard. |
| Freshness violated, availability fine | Upstream pipeline is lagging. Annotate panels that depend on it; don't alert harder. |
| Correctness violated | Treat as a schema change: update JSONPath/validations and the unit tests before re-enabling. |

## Revisiting an SLO

An SLO that is always violated without anyone being affected is wrong, not strict. Change it —
in Git, with the reason in the commit message and in [slo-decisions.md](slo-decisions.md):

1. Change the objective or threshold in `slos/*.yml` or `prometheus/rules/sli.yml`.
2. `docker compose run --rm sloth-generate`, then `promtool test rules` (CI does both and fails on drift).
3. Reload Prometheus: `curl -X POST http://127.0.0.1:9091/-/reload`.

Tightening is just as valid: if a provider has delivered 99.99 % for months, a 99 % objective hides
regressions.

## Review cadence

- Weekly: glance at the SLO catalogue table (budget left, 3-day burn).
- Monthly: for every SLO ask *did this alert ever fire? did it matter when it did?* Remove SLOs
  nobody would act on.
