# Implementation Plan: Audit Hulu-ke-Hilir — Frontend-Only Findings

## Overview

Audit lima-axis (data layer, state management, presentation, performance, security)
terhadap seluruh aplikasi. Daftar ini **sudah difilter**: dua temuan yang murni
kontrak/kendali backend telah dikeluarkan karena tidak actionable dari sisi mobile:

- `access_token` / `client_secret` dikirim via query string — kontrak OAuth backend
  (Ruby/Doorkeeper-style), bukan pilihan desain mobile.
- Request API tidak mendukung `page`/`limit` — endpoint backend tidak menyediakan
  parameter pagination; mobile tidak bisa memaksanya dari sisi request.

**Catatan penting:** untuk item performa terkait payload besar, bagian "tidak ada
pagination di request" dikeluarkan, tapi bagian **"parsing JSON besar berjalan
sinkron di UI thread"** tetap masuk daftar — ini murni bug mobile (harus pakai
`compute()`/isolate) dan sama sekali tidak butuh perubahan backend.

Item lama yang sudah disepakati untuk dilewati dulu (bukan bagian plan ini):
- Cart `addItem` race condition (item #5 dari audit sebelumnya, deferred oleh user).

## Architecture Decisions

- Reuse helper yang sudah ada: `safeMapList()` (`lib/core/utils/safe_json_list.dart`)
  untuk semua cast list-of-map yang belum pakai itu, jangan buat helper baru.
- Migrasi `StateNotifier` → `Notifier`/`AsyncNotifier` dan state → `@freezed`
  dikerjakan sebagai task tersendiri per provider (scope besar, jangan digabung
  dengan fix lain di file yang sama).
- Route args tetap harus lewat class `<Feature>RouteArgs`, tidak ada `Map` mentah
  di `extra`.
- Perbaikan performa mengikuti urutan: memoize/parse-once dulu (murah, dampak
  besar) sebelum masuk ke `compute()` isolate (lebih mahal, perlu verifikasi
  serialisasi lintas isolate).

## Task List

### Phase 1: Security & Data-Integrity (Critical) — jalur uang / rilis

- [ ] **Task 1** — Cegah `.env` asli ikut ke artifact release (bukan hapus dari pubspec)
  - **Revisi setelah investigasi:** `.env` HARUS tetap ada di `assets:` (`flutter_dotenv`
    baca lewat asset bundle — device/emulator tidak bisa baca filesystem host
    langsung). Menghapusnya dari `assets:` akan merusak `flutter run` lokal tanpa
    `--dart-define`. Solusi sebenarnya: swap isi `.env` jadi kosong SAAT
    `flutter build` release berjalan (setelah dart-define sudah dibaca ke memory),
    lalu restore setelah build selesai — dengan `trap` supaya tetap restore
    walau build gagal.
  - **Files:** `scripts/release.sh` (real file, bukan `build_release.sh` yang
    disebut di `myrules.mdc` — nama di rule sudah usang)
  - **Acceptance:** setelah `flutter build ipa/appbundle --release` via
    `release.sh`, `.env` di working dir kembali ke isi asli (verifiable via
    `git diff` kosong setelah build); artifact rilis tidak lagi membundel
    `.env` berisi secret asli (bisa dicek dengan unzip APK/IPA cari file `.env`).
  - **Size:** S

- [ ] **Task 2** — Guard cast di jalur submit order
  - **Files:** `lib/features/checkout/data/services/checkout_order_service.dart`
    (`createOrderLetter` ~128, `fetchFullOrder` ~515, `getLatestWorkPlace` ~52-63,
    `fetchLeaderByUser` ~94-95)
  - **Acceptance:** semua `jsonDecode(...) as Map`/`as List` diganti guard
    `is Map`/`is List` + `Log.error` sebelum throw/return null; tidak ada
    behavior change untuk response valid.
  - **Size:** M

- [ ] **Task 3** — Stop full re-parse untuk banner total approval
  - **Files:** `lib/features/approval/data/utils/approval_wraps_nominal_sum.dart`
  - **Acceptance:** hitung nominal tanpa `OrderHistory.fromApiJson` penuh per
    wrap; hasil sum sama dengan sebelumnya (regression test).
  - **Size:** S

### Checkpoint: Phase 1
- [ ] `dart analyze` bersih untuk file yang disentuh
- [ ] Test suite terkait (checkout, approval) hijau
- [ ] Review manual: build release script masih jalan tanpa `.env` di asset

### Phase 2: Data-layer cast safety (High → Medium)

- [ ] **Task 4** — Guard cast di service checkout tambahan
  - **Files:** `store_repository.dart` (~65-68), `approval_service.dart` (~25,37-39),
    `local_contact_service.dart` (~17-19,47-49), `approver_model.dart` (~16-19)
  - **Acceptance:** pakai `safeMapList`/guard `is Map` konsisten; tidak ada
    `TypeError` untuk elemen non-Map.
  - **Size:** M

- [ ] **Task 5** — Guard cast sisa di history & profile
  - **Files:** `order_history.dart` (`letter`/`rawDetails`/`rawPayments` ~111-113,
    contacts helper ~31-37), `order_history_provider.dart` (~59-67),
    `user_profile.dart` (~31-38)
  - **Acceptance:** sama seperti Task 4.
  - **Size:** M

- [ ] **Task 6** — Guard cast storage & quotation & lookup providers
  - **Files:** `storage_service.dart` (~94-95, ~537-539), `quotation_model.dart`
    (~275-277, ~348, ~375), `accessory_provider.dart` (~34), `item_lookup_provider.dart`
    (~41), `brand_spec_provider.dart` (~30), `edit_order_header_service.dart` (~272-275)
  - **Size:** M

- [ ] **Task 7** — Tutup empty-catch & bare print (rule wajib: catch harus log)
  - **Files:** `region_service.dart` (~71,91), `customer_repository.dart` (~38-40),
    `notification_handler_service.dart` (~31-32 print → Log), `connectivity_service.dart`
    (~77), `ios_update_checker.dart` (~176), `api_client.dart` (~216-218 debugPrint → Log)
  - **Size:** S

### Checkpoint: Phase 2
- [ ] `dart analyze` bersih
- [ ] Full test suite hijau, tidak ada regresi

### Phase 3: State management — race conditions (High)

- [ ] **Task 8** — Fix quotation `remove`/`update` race vs load
  - **Files:** `quotation_list_provider.dart` (~64-77)
  - **Acceptance:** `remove`/`update` menunggu load selesai sama seperti `add`;
    test regresi: remove sebelum load selesai tidak menghapus draft lain.
  - **Size:** S

- [ ] **Task 9** — Fix favorites load-vs-toggle race
  - **Files:** `favorites_provider.dart` (~8-16, 19-29)
  - **Acceptance:** toggle yang terjadi sebelum load selesai tidak hilang tertimpa.
  - **Size:** S

- [ ] **Task 10** — Fix indirect `clear()` tidak membatalkan fetch in-flight
  - **Files:** `indirect_session_provider.dart` (~26-28, 89-91)
  - **Acceptance:** `clear()` juga membatalkan `_pendingFetchAddressNumber`.
  - **Size:** S

- [ ] **Task 11** — Fix sales-mode `_load()` vs `setMode()` race
  - **Files:** `sales_mode_provider.dart` (~10-21, 24-30)
  - **Acceptance:** `setMode()` yang dipanggil sebelum `_load()` selesai tidak tertimpa.
  - **Size:** S

- [ ] **Task 12** — Tambah in-flight guard di `AuthNotifier.login()`
  - **Files:** `auth_provider.dart` (~171-172)
  - **Size:** XS

### Checkpoint: Phase 3
- [ ] Unit test baru untuk setiap race yang diperbaiki
- [ ] Full test suite hijau

### Phase 4: Presentation-layer (High → Medium)

- [ ] **Task 13** — Ganti `FutureBuilder` di `profile_version_footer.dart`
  - **Files:** `profile_version_footer.dart`, tambah `FutureProvider<PackageInfo>`
  - **Size:** S

- [ ] **Task 14** — Typed route args untuk navigasi edit dari cart
  - **Files:** `cart_item_card.dart` (~68-87), buat `ProductDetailRouteArgs`
    atau reuse pola yang ada, update `app_router.dart` bila perlu.
  - **Size:** M

- [ ] **Task 15** — Ganti `Navigator.pop` mentah untuk stack-level pop
  - **Files:** `cart_item_card.dart` (~74), `cart_sheet_footer.dart` (~114-115),
    `product_detail_page.dart` (~1348, 1357) → pakai `context.pop()` /
    `GoRouterPopScope.handlePop`.
  - **Size:** M

- [ ] **Task 16** — Tambah `mounted`/`ref`-safety setelah date-range picker
  - **Files:** `approval_inbox_page.dart` (~104-118), `order_history_page.dart` (~82-91)
  - **Size:** XS

### Checkpoint: Phase 4
- [ ] Manual smoke test navigasi cart → product detail → back
- [ ] Full test suite hijau

### Phase 5: Performance (Critical/High yang murni mobile-side)

- [ ] **Task 17** — Offload parsing JSON besar ke `compute()`
  - **Files:** `product_provider.dart` (~384-399, ~434-486), `order_history_provider.dart`
    (~39-68), `approval_inbox_provider.dart` (~456-591), `store_repository.dart` (~48-75)
  - **Scope note:** HANYA bagian parsing (`jsonDecode` + `fromJson` mapping)
    dipindah ke isolate via `compute()`. TIDAK menambah pagination di request
    (itu backend-dependent, di luar scope).
  - **Acceptance:** UI tidak freeze saat payload besar; hasil data identik.
  - **Size:** L (pisah per file jadi 4 sub-task kalau perlu)

- [ ] **Task 18** — Debounce search yang belum ada
  - **Files:** `quotation_history_page.dart` (~58-60), `searchable_store_bottom_sheet.dart`
    (~120-132)
  - **Size:** S

- [ ] **Task 19** — Persempit `ref.watch` di `product_list_page.dart` biar tidak rebuild seluruh grid
  - **Files:** `product_list_page.dart` (~47-54, 132-137, 255-260)
  - **Size:** M

- [ ] **Task 20** — Split god-files yang jauh melebihi limit
  - **Files (top offenders):** `checkout_page.dart` (2641 baris, limit 400),
    `pricelist_custom_line_page.dart` (1918), `checkout_order_service.dart` (1447,
    limit 500), `checkout_provider.dart` (1407, limit 400), `product_detail_page.dart`
    (1375), `order_detail_page.dart` (1168)
  - **Note:** task besar per file, jangan digabung — kerjakan satu file per PR.
  - **Size:** XL per file → pecah lagi saat mulai

### Checkpoint: Phase 5
- [ ] Profiling manual (DevTools) sebelum/sesudah untuk 1 payload besar
- [ ] Full test suite hijau

### Phase 6: Security (yang actionable dari mobile)

- [ ] **Task 21** — Stop logging response body mentah ke Crashlytics
  - **Files:** `checkout_models.dart` (~103-107), `checkout_provider.dart` (~716-717),
    `checkout_order_service.dart` (~666-668), `approval_service.dart` (~41-42)
  - **Acceptance:** pesan error tetap informatif tapi tidak menyertakan body
    mentah (redact/truncate lebih agresif atau hanya log status+field kunci).
  - **Size:** S

- [ ] **Task 22** — Pindahkan PII (email, saved customer) dari SharedPreferences ke secure storage
  - **Files:** `storage_service.dart` (~147-167), `local_contact_service.dart` (~14-40)
  - **Size:** M

- [ ] **Task 23** — Re-fetch approval detail dari API alih-alih percaya payload FCM mentah
  - **Files:** `notification_handler_service.dart` (~231-292)
  - **Size:** M

- [ ] **Task 24** — Allowlist path untuk deep link sebelum `router.go(path)`
  - **Files:** `main.dart` (~198-201)
  - **Size:** S

### Checkpoint: Phase 6 (Final)
- [ ] Semua test hijau
- [ ] Security review manual pass

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Migrasi `StateNotifier`→`Notifier` (di luar plan ini, task terpisah) menyentuh banyak file besar | High | Jangan digabung ke plan ini; jadwalkan sebagai proyek sendiri per provider |
| `compute()` butuh objek yang bisa dikirim lintas isolate (top-level/static function) | Medium | Pastikan fungsi parsing sudah top-level, tidak menutup `this`/closure state |
| Split god-file berisiko regresi UI besar | High | Satu file per PR, screenshot before/after, tidak digabung fix lain |
| Hapus `.env` dari asset bisa merusak dev-flow tim lain | Medium | Pastikan dev tetap bisa load `.env` via `flutter_dotenv` dari filesystem lokal (bukan asset), dokumentasikan ke tim |

## Open Questions

- Apakah tim backend bisa dikonfirmasi soal opsi `Authorization` header untuk
  OAuth (di luar scope plan ini, hanya untuk referensi ke depan).
- Apakah ada kebijakan retensi data di Crashlytics yang perlu diselaraskan
  sebelum Task 21 (redact response body)?
