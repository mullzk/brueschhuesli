# Brüschhüsli

Although publicly accessible, the Brueschhuesli-Project is taylored for a single use. It is the Reservation-System for our families weekend-cabin. 

## Stack

- Ruby 3.3.5, Rails 8, Puma
- MySQL via `trilogy`
- Hotwire (Turbo + Stimulus), Importmap, Propshaft
- Minitest + FactoryBot + Capybara

## Local setup

```bash
cp .env.example .env          # fill in DATABASE_URL + DEPLOY_* vars
bundle install
bin/rails db:schema:load      # needs a local MySQL DB
bin/rails server
```

## History
v1.0, 2010: Developed as one of my first Rails-Projects, in local git-repo only
v2.0, 2019: Newly initialized repo on github, complete new and responsive view-code
v3.0, 2026 (this version): Configuration for deployment on new infrastructure. 

## Testing

```bash
bin/rails test                # full suite
bin/rake                      # same (default task)
```

## Branch model & deployment

| Branch       | Stage       |
|--------------|-------------|
| `main`       | integration |
| `production` | production  |

GitHub Actions runs the test suite and linters on pull requests. Pushes to
`main` trigger a Capistrano deploy to integration; pushes to `production`
trigger a deploy to production. Merges are gated by the required `test` and
`lint` status checks on the protected branches.

Manual deploy:

```bash
bundle exec cap integration deploy
bundle exec cap production deploy
```

Secrets live in `shared/config/env` on the server — never commit env values.

## DB sync

```bash
bin/rails 'db:pull[integration]'   # pull remote DB into local
bin/rails 'db:push[integration]'   # push local DB to remote (with prompt)
```

## Security & linting

```bash
bin/rubocop                   # Ruby style (Omakase)
bin/brakeman -q -w2           # static security scan
bin/bundler-audit --update    # CVE check
```

All three are CI gates on pull requests. Run everything CI does (lint +
tests) in one go with `bin/ci`.

Git hooks (enabled automatically by `bin/setup`, or manually with
`git config core.hooksPath .githooks`):

- **pre-commit** — RuboCop on staged Ruby files only (sub-second).
- **pre-push** — Brakeman + bundler-audit.