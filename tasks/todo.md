# Todo: Audit Hulu-ke-Hilir — Frontend-Only Findings

> Backend-dependent items (query-string OAuth credentials, request-side pagination)
> DIKELUARKAN dari list ini per keputusan user. Lihat `tasks/plan.md` untuk detail.

## Phase 1 — Critical (jalur uang / rilis)
- [x] Task 1: Cegah `.env` asli ikut ke artifact release (scrub sementara + restore via trap di `release.sh`)
- [x] Task 2: Guard cast di `checkout_order_service.dart` (createOrderLetter, fetchFullOrder, getLatestWorkPlace, fetchLeaderByUser)
- [x] Task 3: Stop full re-parse `OrderHistory` di `approval_wraps_nominal_sum.dart` (+ test baru)

## Phase 2 — Data-layer cast safety
- [x] Task 4: Guard cast — store_repository, approval_service, local_contact_service, approver_model (+ test)
- [x] Task 5: Guard cast — order_history.dart (letter/rawDetails/rawPayments/contacts), order_history_provider, user_profile
- [x] Task 6: Guard cast — storage_service, quotation_model, accessory_provider, item_lookup_provider, brand_spec_provider, edit_order_header_service
- [x] Task 7: Tutup empty-catch tanpa Log + bare print → Log

## Phase 3 — State management races
- [x] Task 8: Quotation remove/update race vs load
- [x] Task 9: Favorites load-vs-toggle race
- [x] Task 10: Indirect clear() tidak cancel fetch in-flight
- [x] Task 11: Sales-mode _load() vs setMode() race
- [x] Task 12: AuthNotifier.login() in-flight guard

## Phase 4 — Presentation layer
- [x] Task 13: Ganti FutureBuilder di profile_version_footer.dart
- [x] Task 14: Typed route args navigasi edit dari cart
- [x] Task 15: Ganti Navigator.pop mentah (stack-level) → context.pop/GoRouterPopScope
- [x] Task 16: mounted-safety setelah date-range picker

## Phase 5 — Performance (murni mobile-side, exclude pagination)
- [x] Task 17: Offload parsing JSON besar ke compute() (pricelist, order history, approval inbox, store list)
- [x] Task 18: Debounce search (quotation history, store picker)
- [ ] Task 19: Persempit ref.watch di product_list_page.dart
- [ ] Task 20: Split god-files (checkout_page.dart dkk) — kerjakan satu per satu, task tersendiri

## Phase 6 — Security (actionable dari mobile)
- [ ] Task 21: Stop log response body mentah ke Crashlytics
- [ ] Task 22: PII (email, saved customer) SharedPreferences → secure storage
- [ ] Task 23: Re-fetch approval detail dari API, jangan percaya payload FCM mentah
- [ ] Task 24: Allowlist path deep link sebelum router.go(path)

## Deferred (bukan bagian plan ini)
- Cart `addItem` race condition — ditunda oleh user
- Migrasi `StateNotifier` → `Notifier`/`AsyncNotifier` + `@freezed` state — proyek tersendiri, terlalu besar untuk disisipkan
- Backend-dependent: access_token/client_secret via query string, request-side pagination
