# Daily Merchant Risk Reporting Challenge

## Overview

This exercise is designed to assess your hands-on data engineering skills in building reliable from-raw pipelines, handling messy real-world data, and ensuring correctness and quality.

### Deliverables

You are expected to deliver:
1. A data pipeline that reads sample CSVs and produces a **daily merchant risk report**.
2. A strategy for handling edge cases (duplicates, out-of-order events, partial captures, refunds, disputes, fraud signals).
3. Documentation of assumptions, quality checks, and idempotency behavior.
4. A short design discussion on how your solution would evolve at production scale (see Step 5).

---

## What We Provide

You are given:

### 1) Schema (in `ddl/schema.sql`)

Defines the tables for:
- payment_events
- checkout_payments
- audit_logs
- merchant_daily_risk_reports

### 2) Base data (in `data/`)

Three base CSVs:
- payment_events_base.csv  
- checkout_payments_base.csv  
- audit_logs_base.csv  

These cover only the *happy path* (simple authorized → captured → fraud signal).

### 3) Starter edge case CSVs

Candidate must merge and expand on these:
- duplicates_starter.csv (payment_events schema)
- partial_captures_starter.csv (payment_events schema)
- out_of_order_starter.csv (payment_events schema)
- refunds_starter.csv (payment_events schema)
- disputes_starter.csv (checkout_payments schema)
- fraud_signals_starter.csv (audit_logs schema)

---

## Data Semantics

To keep the exercise well-defined, use these rules:

**Event types** in `payment_events.event_type`:
- `AUTHORIZED` — funds reserved on the customer's card
- `CAPTURED` — funds actually collected (may be partial, and may happen in multiple captures)
- `REFUNDED` — funds returned to the customer (may be partial)

**Dispute statuses** in `checkout_payments.dispute_status`:
- `''` (empty) — no dispute
- `OPEN` — dispute in progress
- `WON` — merchant won the dispute
- `LOST` — merchant lost the dispute

Any non-empty `dispute_status` counts as a dispute.

**Source of truth per metric:**
- `payment_events` is the source of truth for money movement: authorized, captured, and refunded amounts.
- `checkout_payments` is the source of truth for disputes.
- `audit_logs` is the source of truth for fraud signals (`action = 'FRAUD_FLAGGED'`).

You will notice that authorized/captured/refunded amounts are *also* partially represented in `checkout_payments`. This overlap is intentional and realistic — upstream systems often disagree. Do not double count; use the source-of-truth rules above, and consider (and document) how you would detect and report discrepancies between the two sources.

---

## Your Task

### Step 0 — Start Postgres

Make sure you have Docker installed (optional, but recommended), then from the project root directory run:

```shell
docker-compose up -d
```

This starts a Postgres 16 instance on `localhost:5432` with user `postgres` / password `postgres`. If you prefer not to use Docker, any Postgres 15+ instance works — just adjust the connection variables below.

> **Tip:** if port 5432 is already taken by a local Postgres, change the mapping in `docker-compose.yml` to e.g. `"55432:5432"` and set `export PGPORT=55432`.

Set the connection environment variables so that `psql` and the load script can connect:

```shell
export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=postgres
export PGDATABASE=postgres
```

### Step 1 — Create the tables

Run the schema in Postgres:

```shell
psql -f ddl/schema.sql
```

### Step 2 — Load base CSVs

From the **project root directory**, run the provided load script:

```shell
bash ddl/load_data.sh
```

> **Note:** The load script uses relative paths (`data/...`), so it must be run from the project root (on Windows, use WSL or Git Bash). It truncates and reloads the three base tables, so it is safe to re-run — but it will also remove any extra rows you inserted manually.

### Step 3 — Build the pipeline

Your pipeline should produce a table `merchant_daily_risk_reports` with columns:

| metric | description |
|--------|-------------|
| merchant_id | merchant identifier |
| report_date | date of the report |
| total_authorized_amount | sum of authorizations |
| total_captured_amount | sum of captures |
| total_refunded_amount | sum of refunds |
| dispute_count | count of disputes |
| fraud_signal_count | count of fraud records |

The pipeline should handle:
- duplicates (note: duplicated events may arrive with *different* ids — define what "duplicate" means and defend it)
- out-of-order events (consider whether ordering actually affects your daily metrics — document your reasoning, and how you would surface anomalies such as a capture with no prior authorization)
- partial captures and partial refunds (including refunds that land on a later day than the capture)
- disputes that occur before, during, or after the payment lifecycle
- fraud signals counted independently

### Step 4 — Add more tests

Add your own test data (additional CSVs or SQL inserts) to validate your pipeline. Make sure your tests cover every metric in the report, including refunds and disputes.

### Step 5 — Documentation

In a `README_RESULTS.md`, explain:
- your assumptions
- quality checks and invariants
- idempotency behavior
- how your pipeline handles edge cases

Then add a **design discussion** section (prose only, no code required). Suppose this pipeline moves to production at a company processing ~100M payment events per day:
- How would your design change (storage, compute, incremental processing)?
- How do you handle late-arriving events after a day's report has already been published? What is your restatement policy?
- How would you run backfills safely?
- How would you orchestrate, schedule, and monitor this pipeline? What alerts would you set up?

---

## Evaluation Criteria

We are assessing:
✔ Correct metric computation  
✔ Handling of real-world issues  
✔ Idempotency  
✔ Clarity of code and reasoning  
✔ Documentation & explanation  
✔ Quality checks and validation  
✔ Depth and pragmatism of the production-scale design discussion

---

## Recommended Tools

Implement your solution using any of:
- Python (e.g., Pandas / SQLAlchemy / psycopg)
- Spark (PySpark or Scala)
- SQL

Whichever stack you choose, the final report must land in the `merchant_daily_risk_reports` table in Postgres. Be prepared to explain your choices.

---

## Submission & Expectations

- **Time box:** we expect roughly 5–8 focused hours (you'll have a few days to work on this). If you run out of time, submit what you have — a smaller, correct, well-documented solution beats a large unfinished one.
- **What to submit:** a git repository (or zip) containing your pipeline code, your additional test data, and `README_RESULTS.md`, with instructions to run everything from scratch (assume only Docker and your chosen runtime are installed).
- **AI tools:** you may use AI assistants and any internet resources. You are responsible for understanding every line you submit — the follow-up interview will dig into your decisions.

