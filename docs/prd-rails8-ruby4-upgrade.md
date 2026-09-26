# PRD: Rails 6.1 → 8 + Ruby 3.3.0 → 4, New Server Cutover — rbg_pos

> Owner: vonchristian | Status: approved for implementation | Mode: OpenCode executable
> Source: codebase audit 2026-09-26 (read-only) + user decisions

## 1. Goal

Provision a new server, restore `rbg_production` DB + files from old server
(`167.99.64.121`, `/var/www/rbg`), then deploy the Rails 8 + Ruby 4 upgrade PR
with **zero data loss and no breaking changes**.

## 2. Locked decisions

- Jobs: **Migrate Sidekiq 7.2.4 → Solid Queue** (drop Redis finally).
- Assets: **jsbundling (esbuild) + cssbundling (dartsass)**, remove Webpacker 5.4.4 / webpack 4 / Node 16.
- Data: **Adopt full Solid trifecta** — Solid Queue + Solid Cache + Solid Cable, all on Postgres 16/17.
- Order: **provision → restore on `main` → verify parity → deploy upgrade PR → cutover.** Keep old server 7 days as rollback.
- Deploy tool for cutover: Mina (existing, patched `config/deploy.rb:29-53` for Puma 6). Kamal is out of scope for cutover day except for tar-restore procedure documented in §8.

## 3. Baseline (verified)

- `Gemfile:5` Ruby `3.3.0`, `Gemfile:9` Rails `6.1.7.7`, `config/application.rb:14` `load_defaults(6.0)`.
- Scale: ~117 models, 205 controllers, 332 views (319 erb + 9 axlsx), 188 migrations (2017-07-18 → 2026-09-26), 107 `*_spec.rb` (48 models, 22 services, 7 requests, 24 system). `spec/failed_tests.txt` already has ~11 failures — triage first.
- `config/database.yml:81-85` production = `rbg_production / deploy / deploy@rbg` hardcoded, no `DATABASE_URL`. `config/deploy.rb:13-14` old server `167.99.64.121`, `deploy_to: /var/www/rbg`, shared paths include `config/database.yml, log, public/system, tmp/*` + shared dirs `public/assets, public/packs, public/storage, storage`.
- `db/schema.rb:13` version `2026_09_26_203701`, only `plpgsql` extension.
- Data outside Postgres (must rsync, NOT in pg_dump): `storage/` (ActiveStorage Disk, `config/storage.yml:5-7`), `public/system/{avatars,spreadsheets}` (legacy Paperclip remnant), `public/packs|assets`.
- Legacy: `webpacker 5.4.4`, `turbolinks 5.2.1` + `@rails/ujs` (`app/javascript/packs/application.js:7,9`), `sprockets 4.2.1`, `coffee-rails`, `uglifier`, `spring`, `webdrivers 5.3.1`, `database_rewinder 1.0.1`, `mina/mina-puma`, `secrets.yml` with checked-in secret, `cache_classes` in environments.
- Hard blockers: `paperclip 6.1.0` (0 uses — remove), `axlsx` git fork (dup of `caxlsx` — remove), `audited 4.10` (`activerecord <6.2` cap), `active_interaction 5.3` (`activemodel <8` cap), `roo 2.7.0` (pins `rubyzip <2`), `redis ~>4.0`, `listen <3.2`, `ffi 1.15.3` pinned.
- Infra: Puma 6.6.0 threads-only, Sidekiq 7.2.4 (1 job: `InventoryReportRebuilderJob`), Redis 4.8.1, pg 1.5.6, CI `postgres:11-alpine` + `setup-ruby@v1`, no Node in CI, `config/cable.yml:production` → redis.

## 4. Target architecture (Rails 8 defaults)

| Concern | From | To |
|---|---|---|
| Ruby | 3.3.0 | 3.3.latest → 3.4 → 4.0 (only after rails >= 8.0.2) |
| Rails | 6.1.7.7, defaults 6.0 | 8.0.x, defaults 8.0 (`6.1→7.0→7.1→7.2→8.0` stepwise) |
| JS/CSS | Webpacker 5 + webpack 4 + Sprockets | jsbundling (esbuild) + cssbundling (dartsass); `javascript_pack_tag` → `javascript_include_tag` (`app/views/layouts/application.html.erb:8`, `signin.html.erb:11`) |
| Interactivity | Turbolinks + UJS (`remote:true` ~57 hits, `method::delete` + `data-confirm`) | Hotwire: `turbo-rails ~>2` (Drive/Frames/Streams) + `stimulus-rails`; `turbolinks:load` → `turbo:load`, `data-turbolinks` → `data-turbo`, `remote:true` → `data-turbo=true`, `method:delete` → `data-turbo-method` |
| Jobs | Sidekiq + Redis | Solid Queue (`bin/jobs`, `config/recurring.yml`, Mission Control) |
| Cache | file/mem stub (`production.rb:59` commented) | Solid Cache (`config.cache_store = :solid_cache_store`) |
| Cable | Redis (`cable.yml:production`) | Solid Cable (`adapter: solid_cable`) |
| Secrets | `secrets.yml` (removed in Rails 8) | credentials + ENV (`RAILS_MASTER_KEY`, `DATABASE_URL`) |
| Config | `cache_classes`, `legacy_connection_handling` | `enable_reloading`, Rails 8 defaults |
| Deploy | Mina (keep for cutover) | Mina now; Kamal 2 + Thruster later (needs new Dockerfile) |
| PG | 11 (CI) / unknown prod | 16/17 new server; `pg` gem `1.5.6 → 1.6.x`; add `pg_trgm` + `unaccent` extensions for `pg_search` |

Rails 8 features gained: Solid Queue (DB jobs, transactional, no Redis ops), Solid Cache (DB cache, encrypted, auto-trim), Solid Cable (DB cable, no Redis), Hotwire (SPA feel with ERB intact), Thruster/Kamal path, `rails healthcheck /up`.

## 5. Implementation phases (OpenCode: one PR per sub-phase, gate evidence in PR body)

### Phase 0 — Baseline + safety net
- [ ] Bump patch-only: Ruby `3.3.0 → 3.3.7+`, `pg → 1.6.x`, pin `puma ~>6.4`.
- [ ] CI: `checkout@v3→v4`, PG `11-alpine → 16/17`, add Node 20/22 + `yarn install` + `assets:precompile` step.
- [ ] Harness: `webdrivers → selenium-webdriver >=4.11`, separate `raise_server_errors=true` job, replace `database_rewinder 1.0.1` with transactional fixtures or `database_cleaner-active_record`, remove bogus `group: :production` on `factory_bot_rails`/`faker` lines in `Gemfile:67-68`.
- [ ] Triage `spec/failed_tests.txt` (~11 failures) to green-baseline; record perf/error baselines.
- [ ] Rotate leaked `config/secrets.yml` prod secret; introduce `credentials`/ENV.
- [ ] Gates: `bundle install`, `rails zeitwerk:check`, `db:schema:load`, fast specs, `rubocop --parallel`.

### Phase 1 — Remove dead weight (on Rails 6.1, low risk)
- [ ] Delete `paperclip`, `axlsx` fork, `coffee-rails` (convert `.coffee→.js` first), `spring`, `precise_distance_of_time_in_words` (use built-in helper), consolidate `barby`→`rqrcode`, drop `will_paginate` (keep `pagy 8.4→9.x`).
- [ ] `uglifier → terser`, `listen <3.2 → ~>3.8`, `ffi 1.15.3 → >=1.17`, `redis ~>4 → ~>5` (transitional).
- [ ] `roo 2.7.0 → creek|simple_xlsx_reader|roo-xls`, then `rubyzip 1.3→2.3.x`, `caxlsx 4.1→4.2+`, `caxlsx_rails 0.6.3→0.6.4+`.
- [ ] `audited 4.10→~>5.4`, `money-rails 1.15→1.16+` (or remove — no `monetize` in `app/`), `pg_search 2.3.6→2.7+`, `devise 4.9.4→latest 4.9.x` + `devise_invitable→latest`, `active_interaction 5.3→5.5+`, `sidekiq 7.2→~>8` (temp), `pundit/groupdate/simple_calendar/chartkick/mini_magick/prawn/pdf-reader/bootsnap` latest minor.

### Phase 2 — Step Rails defaults (never jump)
- [ ] `6.0→6.1`: uncomment `new_framework_defaults_6_1.rb`, fix `form_with`, `cookies_same_site`, `urlsafe_csrf_tokens`.
- [ ] `6.1→7.0`: `rails app:update`, STI regression specs (`accounts/amounts/vouchers/invoices/updates` subclasses, `store_full_class_name=false`).
- [ ] `7.0→7.1`: `cache_classes→enable_reloading`, remove `legacy_connection_handling`, audit `serialize` coder, `secrets→credentials`, `dartsass-rails 0.5→1.x`.
- [ ] `7.1→7.2→8.0`: keep `sprockets-rails>=3.5` temp; verify `belongs_to` required, `raise_on_open_redirects`, `run_after_transaction_callbacks`.

### Phase 3 — Frontend (highest UI risk, strangler)
- [ ] Add `jsbundling-rails` + `cssbundling-rails`; port `app/javascript/packs/application.js → app/javascript/application.js`; upgrade `package.json` (Bootstrap 4→5, chart.js→v4, current chartkick JS); move `jquery-rails/jquery-ui-rails/autonumeric-rails` to npm or drop.
- [ ] Add `turbo-rails ~>2` + `stimulus-rails`; codemod `turbolinks:load→turbo:load`, `data-turbolinks→data-turbo`, `remote:true→turbo`, `method:delete+confirm→turbo-method/confirm`, remove `ujs.start()`; ship Turbo Drive per-layout opt-in (`data-turbo=false` fallback) then global.
- [ ] Convert `chosen-js`/`bootstrap-datepicker` init to Stimulus controllers; verify with system specs before removing `turbolinks/webpacker/coffee-rails`.

### Phase 4 — Solid trifecta
- [ ] `bin/rails solid_queue:install`, `queue_adapter=:solid_queue`, `bin/jobs` (Puma plugin or separate process); migrate `InventoryReportRebuilderJob` + schedules to `config/recurring.yml`; dual-run drain Sidekiq → remove `sidekiq/redis/dump.rdb`; add Mission Control.
- [ ] `bin/rails solid_cache:install`, `cache_store=:solid_cache_store`; monitor `solid_cache_entries` growth + trim job; cold-cache deploy acceptable.
- [ ] `bin/rails solid_cable:install`, `cable.yml production adapter: solid_cable`; verify no `Redis.new` leftovers.

### Phase 5 — Ruby 4
- [ ] Ruby `3.3→3.4` with `-W:deprecated`: fix kwargs delegation (`*args→*args,**kwargs,&block`, `ruby2_keywords`), `it` block shadowing, add missing `require "csv"` (reports use `CSV.generate_line`), `rubocop 1.63→1.7x` (+rails/rspec, decide keep/drop `rubocop-shopify`).
- [ ] Ruby `3.4→4.0` only after `rails>=8.0.2`; verify `ffi/sass-embedded/nokogiri/pg` ARM+linux builds; full suite.

### Phase 6 — New server provision + restore + deploy (runbook)
- [ ] Provision: Ubuntu 22.04/24.04, Ruby target, Node 20/22+yarn, PG 16/17+libpq-dev, nginx, vips/imagemagick; `/var/www/rbg/shared/...` per `config/deploy.rb:21-22`; place `shared/config/database.yml` (ENV, new password, `DATABASE_URL` support), `master.key`, env (`RAILS_ENV, DATABASE_URL, RAILS_MAX_THREADS, RAILS_SERVE_STATIC_FILES=1, RAILS_LOG_TO_STDOUT=1`); snapshot VM.
- [ ] Old dump (frozen): stop sidekiq/puma writes, `pg_dump -Fc --no-owner --no-acl -d rbg_production -f /tmp/rbg_YYYY-MM-DD.dump`, `md5sum`, rowcounts (`users, vouchers, ...`), `du -sh storage public/system`; `scp` off-box. Note: if old PG << new, dump with new `pg_dump -h old` or `--no-collation-version`.
- [ ] New restore (on `main` first): `createuser/deploy`, `createdb -O deploy rbg_production`, `CREATE EXTENSION plpgsql pg_trgm unaccent`, `pg_restore --no-owner --no-acl`, verify md5+counts, `rsync storage/ public/system/`, deploy old `main` via Mina to new IP, `db:migrate:status` all `up` thru `2026_09_26_203701`, smoke test.
- [ ] Deploy upgrade PR: `git:clone→link_shared→bundle→db:migrate→assets:precompile` (**never `schema:load/seed`** — Solids tables migrate additively); boot `puma + bin/jobs`; gates `zeitwerk:check`, `migrate:status`, fast specs, `/up`, manual smoke (Turbo forms, delete+confirm, datepicker/chosen, pg_search, upload, xlsx/csv, Devise).
- [ ] Cutover: TTL 300s day before; final delta dump+rsync; DNS/floating-IP to new; monitor `production.log`, `solid_queue_failed_executions`, `/up`. Keep old 7 days; rollback = DNS back + restart old.

## 6. Acceptance criteria

- [ ] Restored rowcounts match old ±0, `storage/` bytes match, old `main` boots on new.
- [ ] Upgrade PR: bundle clean, zeitwerk clean, `migrate:status` all up incl. `solid_*`, fast specs pass, assets precompile, Puma+Jobs boot.
- [ ] Manual smoke: login/invite, search, sale, upload, PDF/xlsx, Turbo nav, cable connect, cache hits.
- [ ] Rollback drill documented: old intact, new snapshot pre-PR.

## 7. Verification commands (per PR)

```bash
bundle install
bin/rails zeitwerk:check
bin/rails db:migrate:status
bin/rails db:migrate RAILS_ENV=test && bundle exec rspec spec/models spec/services spec/requests spec/jobs spec/forms
bundle exec rubocop --parallel
NODE_ENV=production RAILS_ENV=production bundle exec rails assets:precompile
curl -I http://localhost:3000/up
```

## 8. Appendix — Kamal tar dump restore (if Kamal path chosen later)

Kamal core has no `restore` cmd; restore via Postgres accessory `exec`:

```bash
kamal app stop
scp /tmp/rbg.dump deploy@<new-ip>:/tmp/
kamal accessory exec db -- dropdb -U deploy --if-exists rbg_production
kamal accessory exec db -- createdb -U deploy -O deploy rbg_production
kamal accessory exec db -- psql -U deploy -d rbg_production -c "CREATE EXTENSION IF NOT EXISTS plpgsql; CREATE EXTENSION IF NOT EXISTS pg_trgm;"
# custom/tar format:
kamal accessory exec db -- pg_restore --no-owner --no-acl -U deploy -d rbg_production /tmp/rbg.dump
# plain SQL tar.gz:
# tar xzf dump.sql.tar.gz -O | kamal accessory exec db -- psql -U deploy -d rbg_production -f -
kamal accessory exec db -- psql -U deploy -d rbg_production -c "SELECT count(*) FROM users;"
kamal deploy  # runs db:migrate for Solids on top of restored data
```

`kamal-backup` gem (restic) is for post-cutover scheduled backups, not for this one-off tar.

## 9. Out of scope

Mina→Kamal full migration (keep Mina patch), Propshaft switch, Bootstrap 5 redesign, old-server PG upgrade, data cleanup/backfill.

## 10. OpenCode task split (suggested issue order)

1. `Phase0-harness-ci` 2. `Phase1-gem-cleanup` 3. `Phase2-rails-steps` 4. `Phase3-frontend-hotwire` 5. `Phase4-solids` 6. `Phase5-ruby4` 7. `Phase6-provision-restore-deploy`. One branch + PR each, gate evidence in body, never combine restore + upgrade in same PR.
