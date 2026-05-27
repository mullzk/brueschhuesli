# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Brüschhüsli — Rails 8 reservation system for a family weekend cabin. Solo-maintained, single deployment target, mature/frozen feature set. UI is German; code, commits and comments are English.

**Sister projects** in the same workspace (`../mensajasser`, `../webapp_infra`) are intentionally kept architecturally aligned:

- **`mensajasser`** — Rails 8 Jass-statistics app. Acts as the **template** for Capistrano setup, GitHub Actions workflows, deploy layout (`/var/www/<instance>`, `shared/config/env`), mise + Puma + dotenv. When in doubt about deploy/CI structure, mirror mensajasser.
- **`webapp_infra`** — Ansible playbooks provisioning the Hetzner VPS that hosts both Rails apps (nginx + Phusion Passenger + mise + MariaDB). The deploy targets here (`brueschhueslidev`, `brueschhuesliprod`) are configured from there.

## Stack

- Ruby 3.3.5 (`.tool-versions`, managed via mise on servers, rvm/asdf locally)
- Rails 8.x, Puma, MySQL via **trilogy** (no Postgres adapter at runtime — `pg` exists as `require: false` only for `db:import_from_postgres`)
- Hotwire (turbo-rails + stimulus-rails) via **importmap-rails**, **Propshaft** asset pipeline, plain CSS (no Sass/jQuery/CoffeeScript)
- Testing: Rails Minitest + FactoryBot + Capybara/Selenium
- Linting/security: `brakeman`, `bundler-audit` (binstubs under `bin/`)
- Active Storage on local disk (`storage/` is in `linked_dirs` on the server)

## Common commands

```bash
bin/rails server                  # dev server
bin/rails test                    # full suite (32 runs currently)
bin/rails test test/models/reservation_test.rb     # single file
bin/rails test test/models/reservation_test.rb:42  # single test by line
bin/rake                          # default — runs the test suite
bin/brakeman -q -w2               # static security scan (CI gate on PRs)
bin/bundler-audit --update        # CVE check (CI gate on PRs)
bin/rails db:schema:load          # bring an empty MySQL DB up
bundle exec annotaterb models     # refresh `# == Schema Information` headers
```

DB sync between local and deployed instances:

- `rails db:pull[integration|production]` / `db:push[...]` — defined in `lib/tasks/db_sync.rake`, uses `mariadb-dump`/`mariadb` over SSH. Paths come from `DEPLOY_*_HOST/USER` env vars.
- `rails db:import_from_postgres` — one-off Heroku-Postgres → local-MySQL importer in `lib/tasks/db_import.rake`. Kept around for the final cutover; it's the only reason `pg` is in the Gemfile.

Local env via `.env` (template in `.env.example`); `DATABASE_URL` is read in all environments.

## Deployment

Capistrano 3, two stages, **GitHub Actions** triggers the deploy after a green test run:

| Branch       | Stage         | Server                              | Path                          |
|--------------|---------------|-------------------------------------|-------------------------------|
| `main`       | `integration` | `brueschhueslidev.mullzk.ch`        | `/var/www/brueschhueslidev`   |
| `production` | `production`  | (TBD — Phase 5 of `roadmap.md`)     | `/var/www/brueschhuesliprod`  |

- Secrets live in `shared/config/env` on each server and are loaded by the `before 'deploy:starting', :load_shared_env` hook in `config/deploy.rb` — **never** commit env values to the repo.
- `config/puma.rb` is environment-driven (`PUMA_SOCKET`); the old hardcoded `ssl_bind` is gone, Passenger fronts Puma via nginx.
- `linked_dirs` covers `log tmp/pids public/system storage`. Adding state that must survive deploys means adding it here.

Heroku is being phased out. Current status and remaining cutover steps are tracked in `roadmap.md` (gitignored — read but don't commit).

## Domain model (the bits worth knowing before editing)

Two models: `Reservation` (cabin booking) and `User` (owner/co-owner/guest). All non-trivial logic lives in `app/models/reservation.rb`.

- **`type_of_reservation` is overridden on read** (`reservation.rb:103`): the getter swaps `KURZAUFENTHALT` ↔ `FERIENAUFENTHALT` automatically based on `duration` (>48h cutoff). The DB value can disagree with what `.type_of_reservation` returns. When comparing or persisting, be deliberate about which you want — `self[:type_of_reservation]` reads the raw column.
- **Billing constants & rules** (`billed_fee`, `paid_blocks`):
  - Short/long stays: 15 CHF per 8-hour block.
  - Big event (`GROSSANLASS`): flat 200.
  - External use (`EXTERNE_NUTZUNG`): 100 CHF per day — and beware, `duration_in_days` returns *seconds* (commented in source). Don't "fix" this without auditing call sites.
  - Co-owners (`user.miteigentuemer?`) get the first 6 blocks free on non-exclusive reservations.
  - 7-day hard cap enforced as a validation.
- **Overlap validation** (`is_timeslot_exclusive?`) hits `find_reservations_in_timeslot`, which uses raw `where("start <= ? AND finish > ?", ...)` string interpolation with `.to_formatted_s(:db)`. Don't pass user-controlled times here without going through the same formatting pipeline.
- `Reservation.find_reservations_beginning_in_*` are used for billing periods — they intentionally exclude reservations that *span* into the period from earlier. This is load-bearing for the year-end report.

## Auth (legacy, fragile)

`User` rolls its own SHA1+salt auth (`user.rb:48`). `ApplicationController#authorize` is the only access gate and is called via `before_action :authorize` in each controller (e.g. `AbrechnungController`). Anything you add that should require login needs that `before_action` — there's no global default.

Don't replace this with `has_secure_password` opportunistically — it would invalidate every stored password. Any auth rewrite must include a one-shot rehash-on-next-login migration path.

## Frontend

- Importmap pins are in `config/importmap.rb`; JS lives under `app/javascript/`.
- Stimulus controllers replaced the old jQuery-driven calendar interactions.
- Styling is hand-written CSS via Propshaft — no Sass, no PostCSS, no bundler. Add new stylesheets directly under `app/assets/stylesheets/`.

## Locale & date handling

The app is German-locale. `config/initializers/date_german_additions.rb` monkey-patches `Date` with `parse_german_string`, `short_german_std`, `long_german_std`, `german_month`, `strftime_german`. Use those instead of reimplementing translation — they handle the date-format quirks (e.g. two-digit year disambiguation around 1950/2050) used by existing views and forms.

## Conventions

- Commit subjects in English, imperative, ≤50 chars; body wrapped at 72; no Co-Authored-By / no AI attribution.
- Don't auto-commit, auto-push, or open PRs without explicit instruction — surface a suggested message and wait.
- `roadmap.md` is in `.gitignore` deliberately (the working roadmap; keep it updated as phases close, but it's local-only).
- When touching domain rules in `Reservation`, keep the existing German constant strings (`KURZAUFENTHALT`, `FERIENAUFENTHALT`, `GROSSANLASS`, `EXTERNE_NUTZUNG`) — they're persisted in the DB as-is.
