# Roadmap — Brüschhüsli von Heroku auf eigene Infrastruktur

## Context

Brüschhüsli (Rails 7.0.3.1 / Ruby 3.1.0, Postgres, Puma) läuft heute auf Heroku
(Git-Auto-Deploy `master`→prod). Ziel: Umzug auf eigene Server-Infrastruktur,
Deployment per **Capistrano**, getriggert über **GitHub Actions**. Default-Branch
neu **`main`** (→ deployt **integration**), Branch **`production`** (→ deployt
**production**).

Vorlage ist das Schwester-Projekt **`mullzk/mensajasser`**: Capistrano 3 + Phusion
Passenger + **mise** + **dotenv**, zwei Instanzen auf **einem** Server
(`/var/www/<instanz>`), Env-Secrets in `shared/config/env` auf dem Server,
wiederverwendbare GitHub-Actions-Workflows. Server-Konfiguration und Deployment
sollen **identisch** werden.

**Brüschhüsli-Abweichungen:** Postgres bleibt (mensajasser=MariaDB), Ruby 3.1.0
bleibt vorerst (mensajasser=3.3.5, Upgrade erst Phase 4), `storage` zusätzlich in
`linked_dirs` (Active Storage auf lokaler Platte).

Wir gehen die Roadmap **Schritt für Schritt** durch (Checkbox je Schritt).

---

## Phase 1 — Integration-Deployment aufsetzen

### 1.1 Repo-Roadmap anlegen
- [ ] Diese Roadmap als `roadmap.md` ins Repo-Root committen (analog mensajasser).

### 1.2 Gemfile + Dependencies
- [ ] Auskommentierte Zeile 35–36 (`# gem 'capistrano-rails'…`) ersetzen durch
  `group :development do` mit `capistrano '~> 3.18'`, `capistrano-rails`,
  `capistrano-bundler`.
- [ ] `gem 'dotenv-rails'` in `group :development, :test`.
- [ ] `gem 'brakeman'` + `gem 'bundler-audit'` in `group :development, :test`.
- [ ] `bundle install` → `Gemfile.lock` aktualisieren.
- [ ] `bundle binstubs brakeman bundler-audit` → erzeugt `bin/brakeman`,
  `bin/bundler-audit` (fehlen aktuell → kaputter Lint-Job).

### 1.3 Capistrano-Grundgerüst (Vorlage mensajasser)
- [ ] `Capfile` wörtlich von mensajasser übernehmen.
- [ ] `config/deploy.rb` von mensajasser übernehmen, anpassen:
  - `set :application, "brueschhuesli"`
  - `set :repo_url, "git@github.com:mullzk/brueschhuesli.git"`
  - `set :linked_dirs, %w[log tmp/pids public/system storage]` ← **`storage` ergänzt**
  - `set :keep_releases, 5`
  - `set :default_env, { path: ".../.local/share/mise/shims:$PATH" }` (mise-Pfad)
  - `before 'deploy:starting', :load_shared_env` unverändert übernehmen
  - `namespace :deploy { task :restart }` + `after :publishing, :restart` unverändert
- [ ] `config/deploy/integration.rb`: `application_instance "brueschhueslidev"`,
  `branch "main"`, `deploy_to "/var/www/brueschhueslidev"`, `server ENV.fetch("DEPLOY_INTEGRATION_HOST")`
  user `ENV.fetch("DEPLOY_INTEGRATION_USER")` roles `app db web`.
- [ ] `config/deploy/production.rb`: `application_instance "brueschhuesliprod"`,
  `branch "production"`, `deploy_to "/var/www/brueschhuesliprod"`, `DEPLOY_PRODUCTION_*`.

### 1.4 App-Konfiguration angleichen
- [ ] `config/puma.rb` durch mensajasser-Variante ersetzen: `PUMA_SOCKET`-Branch,
  `plugin :tmp_restart`, **hardcoded `ssl_bind …localhost.mullzk…` entfernen**
  (auskommentiert lassen wie Referenz).
- [ ] `config/environments/production.rb`: `config.force_ssl = true` aktivieren;
  STDOUT-Logger wie mensajasser immer aktiv.
- [ ] `config/database.yml`: `production:` auf `DATABASE_URL` umstellen
  (Adapter bleibt `postgresql`; Wert kommt aus `shared/config/env`).
- [ ] `.tool-versions` neu: `ruby 3.1.0`.
- [ ] `.gitignore`: `.env` → `.env*`.
- [ ] `.env.example` neu (DATABASE_URL postgresql + `DEPLOY_*_HOST/USER`).

### 1.5 Datenbankwechsel: Postgres → MySQL (trilogy)

**Entscheidung (2026-05-25):** Lokal und auf den neuen Servern wird
ausschliesslich MySQL verwendet (wie mensajasser). Postgres fällt weg
sobald Heroku nicht mehr im Spiel ist. Gem: `trilogy` (nicht `mysql2`).

- [ ] Gemfile: `pg` → `trilogy`.
- [ ] `bundle install` → Gemfile.lock aktualisieren.
- [ ] `database.yml`: adapter `trilogy`, encoding `utf8mb4`, alle
  Environments via `DATABASE_URL` (analog mensajasser).
- [ ] `.env.example`: `DATABASE_URL` auf `trilogy://...` umstellen.
- [ ] Lokale MySQL-DB einrichten: `brueschhuesli_development` +
  `brueschhuesli_test`.
- [ ] `rails db:schema:load` lokal verifizieren.
- [ ] Reproduzierbaren Weg Heroku-Prod → lokale MySQL erstellen:
  `pg_dump` von Heroku (Postgres) → Konvertierung → MySQL-Import.
  Achtung: keine 1:1-Migration (Datentypen, Sequences →
  AUTO_INCREMENT, Postgres-spezifische SQL-Syntax).
- [ ] `rails test` grün auf MySQL.

**Implikation Phase 6:** Cutover braucht Konvertierungsscript
Postgres → MySQL (Schema + Daten). Kein einfaches `pg_restore`.

### 1.6 db_sync.rake (MySQL-Variante)
- [ ] `lib/tasks/db_sync.rake` neu, strukturgleich zu mensajasser
  (`mysqldump`/`mysql`). `DEPLOY_PATHS`:
  `integration→/var/www/brueschhueslidev`, `production→/var/www/brueschhuesliprod`.

### 1.7 GitHub Actions
- [ ] `.github/workflows/deploy.yml` neu, 1:1 von mensajasser (workflow_call,
  Input `stage`, ssh-agent `SSH_DEPLOY_KEY`, known_hosts `SSH_KNOWN_HOSTS`,
  `bundle exec cap <stage> deploy` mit `DEPLOY_*` Secrets).
- [ ] `.github/workflows/rubyonrails.yml` umbauen (Struktur mensajasser,
  **Postgres-Service im test-Job behalten**):
  - Trigger `pull_request` + `push` auf `main`/`production`.
  - `lint`-Job nur bei PR: `bin/bundler-audit --update` + `bin/brakeman -q -w2`
    (rubocop-Referenz entfernen).
  - `deploy_integration` (`needs:[test]`, ref `main`, push, stage integration).
  - `deploy_production` (ref `production`, push, stage production).

### 1.8 Branch-Umstellung (GitHub-seitig)
- [ ] Default-Branch `master` → `main` umbenennen.
- [ ] Branch `production` von `main` anlegen.
- [ ] README „Deployment“ durch Maintenance-Workflow von mensajasser ersetzen
  (inkl. „Adding a new deployment server“).

### 1.9 Server-Voraussetzungen (manuell / Ansible — kein Repo-Code)
- [ ] VPS: nginx + Phusion Passenger, mise mit Ruby 3.1.0, Node.js (für
  `assets:precompile` von CoffeeScript/uglifier).
- [ ] Deploy-User + SSH-Key; `/var/www/brueschhueslidev`, `/var/www/brueschhuesliprod`.
- [ ] Pro Instanz `shared/config/env` (`RAILS_ENV`, `RACK_ENV`,
  `RAILS_MASTER_KEY`, `DATABASE_URL`, ggf. `RAILS_SERVE_STATIC_FILES`,
  `SECRET_KEY_BASE`).
- [ ] Pro Instanz Postgres-DB + User.
- [ ] 2 nginx-Server-Blocks (Integration/Production-Host) + TLS (Let's Encrypt).
- [ ] GitHub Secrets: `SSH_DEPLOY_KEY`, `SSH_KNOWN_HOSTS`,
  `DEPLOY_INTEGRATION_HOST/USER`, `DEPLOY_PRODUCTION_HOST/USER`.

### 1.10 Erstes Deploy Integration
- [ ] `bundle exec cap -T` zeigt Stages/Tasks fehlerfrei.
- [ ] `bundle exec cap integration deploy:check` ok (SSH, shared-Pfade).
- [ ] `shared/config/env` befüllen.
- [ ] `bundle exec cap integration deploy` → App über Integration-Host (HTTPS)
  erreichbar; Login/Kalender/Reservierung funktionieren.
- [ ] Push auf `main` → Auto-Deploy via GitHub Actions grün.

---

## Phase 2 — Daten Heroku-Prod → Integration

- [ ] Active Storage prüfen: existieren Uploads auf Heroku? (flüchtiger
  Speicher) — falls ja, separat sichern.
- [ ] `pg_dump $(heroku config:get DATABASE_URL)` — Postgres-Dump von Heroku.
- [ ] Postgres → MySQL konvertieren (Konvertierungsscript aus 1.5 verwenden).
- [ ] Schema aktuell halten: `cap integration deploy` (führt `db:migrate` aus).
- [ ] Konvertierten Dump in Integrations-MySQL einspielen; Datenstand verifizieren.

## Phase 3 — Testsuite sauber grün

- [ ] `bin/rake` lokal + in CI; offene Failures fixen (Auth, Abrechnung,
  fixtures-Altlasten). Voraussetzung für gefahrlose Phase 4.

## Phase 4 — Updates (Ruby/Rails + Bundle-Updates, z.T. security)

- [ ] Ruby 3.1.0 → 3.3.5 (`.tool-versions`, Gemfile `ruby`); mise auf Server um
  3.3.5 ergänzen.
- [ ] Rails 7.0 → 7.1 → 7.2 (→ 8.0): je `rails app:update` + `rails test`.
- [ ] Alle aufgelaufenen Dependabot-/Security-Bundle-Updates einspielen.
- [ ] Über Integration verifizieren.

## Phase 5 — Production deployen

- [ ] `brueschhuesliprod`-Server-Instanz fertig einrichten (analog 1.8).
- [ ] `cap production deploy:check` → erstes `cap production deploy`.
- [ ] Push auf `production` → Auto-Deploy grün.

## Phase 6 — Datenmigration Heroku → neue Production + Cutover

- [ ] Wartungsfenster: `heroku maintenance:on`.
- [ ] Finaler `pg_dump` Heroku → Postgres→MySQL-Konvertierung →
  Import in `brueschhuesliprod`-MySQL-DB; Storage-Übertrag.
- [ ] Smoke-Test auf neuer Production.
- [ ] **DNS-Umstellung** auf neuen Server.
- [ ] Heroku-App stilllegen (später löschen); README/Memory aktualisieren.

---

## Kritische Dateien (Phase 1)

| Aktion | Datei |
|---|---|
| neu | `roadmap.md`, `Capfile`, `config/deploy.rb`, `config/deploy/integration.rb`, `config/deploy/production.rb` |
| neu | `.github/workflows/deploy.yml`, `.tool-versions`, `.env.example`, `lib/tasks/db_sync.rake` |
| ändern | `Gemfile`, `Gemfile.lock`, `.github/workflows/rubyonrails.yml`, `config/puma.rb`, `config/environments/production.rb`, `config/database.yml`, `.gitignore`, `README.md` |
| binstubs | `bin/brakeman`, `bin/bundler-audit` |
| Vorlage | Schwester-Projekt `mullzk/mensajasser` |
