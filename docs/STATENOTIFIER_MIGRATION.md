# Migrasi `StateNotifier` → `Notifier` (Riverpod 2.x)

## Latar belakang

`StateNotifier`/`StateNotifierProvider` masih berfungsi normal di Riverpod
2.6.1 (versi yang dipakai project ini), tapi sudah ditandai sebagai pola lama
di dokumentasi resmi Riverpod dan berpotensi dibuang di Riverpod 3.x. Ini
**tech debt preventif, bukan bug** — lihat `myrules.mdc` § STATE MANAGEMENT
RULES butir 2: migrasi harus jadi task terpisah, tidak disisipkan saat
mengerjakan hal lain.

Ditemukan saat audit per-fitur (lihat chat 3 Agu 2026): 9 class di 8 file
masih `extends StateNotifier<...>`.

## Yang TIDAK berubah (behavior)

- State yang disimpan, semua method publik, dan cara UI konsumsi provider
  (`ref.watch(xProvider)`) — identik.
- Sintaks `state = newState` di dalam method — identik antara `StateNotifier`
  dan `Notifier`.
- Dependency `state_notifier` di `pubspec.lock` tetap ada (transitif lewat
  `flutter_riverpod` sendiri) — migrasi ini TIDAK menghapus dependency apa pun.

## Yang berubah (struktural, per file)

1. `super(initialState)` di constructor → method `build()` yang
   mengembalikan state awal.
2. Field `final Ref _ref` yang di-inject lewat constructor → getter bawaan
   `ref` (tidak perlu constructor param lagi).
3. `StateNotifierProvider<X, S>((ref) => X(ref))` →
   `NotifierProvider<X, S>(X.new)`.
4. **Kalau ada test yang inject mock lewat constructor** (contoh:
   `AuthNotifier(ref, authService: mockAuthService)`), pola itu HARUS ganti
   jadi override provider service lewat `ProviderContainer(overrides: [...])`,
   karena `Notifier` dipanggil Riverpod lewat constructor tanpa-argumen
   (`X.new`). Ini scope tambahan di luar file notifier itu sendiri.

## Urutan migrasi (mudah → sulit)

Diurutkan dari LOC notifier + LOC test + ada/tidaknya constructor-mock-inject
yang perlu direwrite. Kerjakan satu per satu, masing-masing PR/commit
terpisah, `flutter test` + `dart analyze` hijau sebelum lanjut ke berikutnya.

| # | File | Notifier | LOC notifier | LOC test | Constructor mock-inject? | Catatan |
|---|---|---|---|---|---|---|
| 1 | `indirect/logic/sales_mode_provider.dart` | `SalesModeNotifier` | 56 | 54 | Tidak | Paling simpel, cocok jadi "template" migrasi pertama |
| 2 | `favorites/logic/favorites_provider.dart` | `FavoritesNotifier` | 92 | 106 | Tidak | Simpel, `List<String>` |
| 3 | `cart/logic/cart_provider.dart` | `SelectedCartIdsNotifier` | (bagian dari 368) | (bagian dari 242) | Tidak | Set kecil, tidak ada persistence async |
| 4 | `cart/logic/cart_provider.dart` | `CartNotifier` | (bagian dari 368) | (bagian dari 242) | Tidak | Ada `_loadCartFuture` async di constructor — pindah ke `build()`, perhatikan urutan init |
| 5 | `quotation/logic/quotation_list_provider.dart` | `QuotationListNotifier` | 96 | 179 | Tidak | Persist ke disk (JSON), mirip pola cart |
| 6 | `indirect/logic/indirect_session_provider.dart` | `IndirectSessionNotifier` | 108 | 123 | Tidak | — |
| 7 | `pricelist/logic/master_data_provider.dart` | `MasterDataNotifier` | 243 | 232 | Tidak | Ada logic sync/debounce, uji ulang timing-sensitive test |
| 8 | `approval/logic/approval_inbox_provider.dart` | `ApprovalInboxNotifier` | 689 | **1630** | Tidak | Test terbesar — migrasi notifier-nya sendiri relatif mekanis, tapi review test butuh waktu karena banyak |
| 9 | `auth/logic/auth_provider.dart` | `AuthNotifier` | 353 | 126 | **Ya** — `authService: mockAuthService` | Test HARUS direwrite ke pola override provider, bukan cuma migrasi notifier |
| 10 | `checkout/logic/checkout_provider.dart` | `CheckoutNotifier` | 1446 | 188 | Tidak (pakai `ProviderContainer()` biasa) | File terbesar & paling banyak business logic — kerjakan **terakhir**, setelah pola migrasi sudah matang dari 9 file sebelumnya |

## Checklist per file (template)

- [ ] Ganti `extends StateNotifier<S>` → `extends Notifier<S>`
- [ ] Pindahkan isi constructor (termasuk `_init()`/side-effect awal) ke
      override `S build() { ...; return initialState; }`
- [ ] Ganti semua `_ref.xxx` → `ref.xxx` (getter bawaan), hapus field `Ref _ref`
      kalau tidak dipakai lagi
- [ ] Ganti deklarasi provider: `StateNotifierProvider<X, S>(...)` →
      `NotifierProvider<X, S>(X.new)`
- [ ] Kalau ada dependency constructor lain (misal `AuthService? authService`)
      untuk keperluan test — pindahkan ke provider terpisah
      (`final authServiceProvider = Provider((ref) => AuthService());`) lalu
      baca via `ref.read(authServiceProvider)` di `build()`/method, supaya
      bisa di-override di test lewat `authServiceProvider.overrideWith(...)`
- [ ] Update file test terkait sesuai pola override provider baru
- [ ] `dart analyze` + `flutter test test/features/<fitur>/` hijau
- [ ] `flutter test test/` penuh hijau (regresi ke fitur lain) sebelum commit
- [ ] 1 commit per file/notifier — jangan digabung ke commit fitur lain

## Non-goal

Task ini TIDAK mengubah behavior aplikasi. Kalau saat migrasi ditemukan bug
lama (misal race condition, state stale), catat sebagai temuan terpisah —
jangan sekaligus diperbaiki di commit migrasi yang sama (biar review-nya
tetap murni "structural, no behavior change").
