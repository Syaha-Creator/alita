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

## Progress (3 Agu 2026)

9 dari 10 notifier sudah dimigrasi (commit lokal di branch `feature/toko`,
belum di-push — lihat instruksi user di chat). `CheckoutNotifier` (#10)
**sengaja ditunda**, sesuai urutan yang sudah direncanakan di tabel di
bawah (file terbesar & paling banyak business logic — kerjakan setelah
pola migrasi matang dari 9 file lain).

| # | Notifier | Status |
|---|---|---|
| 1 | `SalesModeNotifier` | ✅ Selesai |
| 2 | `FavoritesNotifier` | ✅ Selesai |
| 3 | `SelectedCartIdsNotifier` | ✅ Selesai |
| 4 | `CartNotifier` | ✅ Selesai |
| 5 | `QuotationListNotifier` | ✅ Selesai |
| 6 | `IndirectSessionNotifier` | ✅ Selesai |
| 7 | `MasterDataNotifier` | ✅ Selesai |
| 8 | `ApprovalInboxNotifier` | ✅ Selesai |
| 9 | `AuthNotifier` | ✅ Selesai |
| 10 | `CheckoutNotifier` | ⏳ Belum — lihat catatan di bawah |

### Temuan tambahan selama migrasi (di luar checklist awal)

1. **Bug halus di `ApprovalInboxNotifier` (#8):** memanggil method yang
   menyentuh `state` secara SINKRON sebelum `await` pertamanya (misal
   `fetchInbox()` yang langsung `state = state.copyWith(isLoading: true)`
   sebelum baris `await`) — aman di constructor `StateNotifier` (karena
   `super(initial)` sudah men-set state lebih dulu), tapi melempar
   `StateError: Tried to read the state of an uninitialized provider` kalau
   dipanggil langsung dari `build()` pada `Notifier` (state belum di-`return`
   dari `build()`). **Fix:** bungkus panggilan awal dengan
   `Future.microtask(fetchInbox)` di dalam `build()`. Sebelum memanggil
   method async apa pun langsung dari `build()`, periksa dulu apakah
   statement PERTAMA method itu adalah `await` — kalau bukan, butuh
   microtask wrapper ini.
2. **Field `mounted` StateNotifier tidak ada penggantinya langsung di
   `Notifier`** (juga tidak ada di `Ref` pada riverpod 2.6.1). Ganti dengan
   flag manual `bool _isDisposed = false;` + `ref.onDispose(() => _isDisposed
   = true);` didaftarkan di `build()` (dipakai di `MasterDataNotifier` #7
   dan `AuthNotifier` #9).
3. **Test yang instantiate notifier langsung** (`SalesModeNotifier()`, dst.)
   harus direwrite ke `ProviderContainer().read(xProvider.notifier)` —
   `Notifier` tidak boleh dipakai berdiri sendiri tanpa di-attach ke
   provider/container (beda dari `StateNotifier` yang aktif sejak
   konstruksi). Baca `.notifier` (atau provider-nya) sekali di awal test
   untuk memicu `build()` yang lazy.
4. **`NotifierProvider.overrideWith` menerima factory tanpa-`ref`**
   (`Notifier<T> Function()`), beda dari `StateNotifierProvider.overrideWith`
   yang meneruskan `ref` ke factory-nya (`(ref) => X(ref, ...)`). Semua
   override di test (dan `integration_test/helpers/test_app.dart`) diupdate
   ke pola `() => X(...)`.
5. **Method pada `Notifier` tidak boleh dipanggil sebelum di-attach oleh
   framework** — di integration test, `cartProvider.overrideWith((ref) {
   final n = CartNotifier(); n.addItem(...); return n; })` tidak bisa lagi
   dipakai (Notifier belum ter-`build()` saat itu). Populate state SETELAH
   widget tree sudah di-pump, lewat
   `ProviderScope.containerOf(...).read(xProvider.notifier).addItem(...)`.

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
