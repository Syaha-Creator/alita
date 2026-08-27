# TODO — Direct checkout + Paper.id

Tracked while implementing Direct payment via Paper on `feature/payment-ui`.

## Done in this branch (MVP)

- [x] Hide manual payment section for Direct (S1); keep for MM
- [x] Direct: payment section shown again — **default manual**, opt-in **Bayar via Paper.id**
- [x] After Direct order success: call Alita Paper staging API
- [x] Success screen + **Bayar via Paper.id** opens `paper_id_invoice_url`
- [x] `payment_number` = `INV/{no_sp}`
- [x] Order detail: parse `paper_id_*`, show Belum/Sudah bayar + **Bayar via Paper.id** for UNPAID

## Still open (need backend / prod)

- [ ] **Confirm prod Paper path** — app memakai `payper_id` saat `APP_ENV=production` (override: `PAPER_PAYMENT_PATH`). Pastikan endpoint prod live di host Alita (bukan hanya localhost).
- [ ] **GET order detail must return `paper_id_invoice_url`** on Paper payment rows — app shows **Bayar via Paper.id** without URL and refreshes once on tap; without this field the browser cannot open
- [x] **Retry** — order steps succeed but Paper call fails: success screen shows recreate CTA (same payload); auto-retry 3x during submit
- [ ] **Edit shortage (Direct)** — whether shortage top-up also goes through Paper or stays on legacy multipart payment form
- [ ] Optional: auto-refresh order detail after returning from Paper browser

## Env (staging / production)

- Dev: `./scripts/use-env.sh staging` → `.env` dari `.env.staging`
- Store release: `./scripts/release.sh …` → default `.env.production` (+ Paper `payper_id`)
- QA staging binary: `./scripts/release.sh --env=staging …`
