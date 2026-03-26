# Alita Pricelist

Aplikasi **Flutter** untuk tim lapangan Massindo: pricelist dinamis, keranjang & checkout, riwayat pesanan, penawaran (PDF), dan alur **persetujuan** pesanan. State management memakai **Riverpod**, navigasi **GoRouter**, dengan integrasi **Firebase** (Auth, Messaging, Crashlytics, Analytics, App Check) dan **Firebase Data Connect** untuk data pelanggan di checkout.

---

## Daftar isi

- [Fitur aplikasi](#fitur-aplikasi)
- [Persyaratan](#persyaratan)
- [Setup](#setup)
- [Menjalankan aplikasi](#menjalankan-aplikasi)
- [Build release & rahasia](#build-release--rahasia)
- [Pengujian](#pengujian)
- [Arsitektur](#arsitektur)
- [Referensi cepat](#referensi-cepat)
- [Dokumentasi internal](#dokumentasi-internal)

---

## Fitur aplikasi

### Autentikasi & sesi

| Fitur | Deskripsi |
|-------|-----------|
| Login API | OAuth2 client credentials ke API Alita (Ruby); sesi disimpan |
| Persistensi | Token, user, area default, dll. (`StorageService` + secure storage) |
| Routing terlindungi | Belum login → halaman login; sudah login → home |
| Firebase Anonymous Auth | Untuk **Data Connect** (token gRPC tanpa UI login terpisah) |

### Pricelist & produk

| Fitur | Deskripsi |
|-------|-----------|
| Daftar produk | Grid masonry/staggered, pencarian, filter area/channel/brand |
| Master data | Sync area, channel, brand dengan cache |
| Detail produk | Carousel gambar, harga, varian, aksesori, simulasi cicilan |
| Diskon & bonus | Modal diskon, editor bonus sesuai aturan produk |
| Deep link produk | `/product/:id` — buka detail dari link tanpa navigasi penuh |
| Cache besar | Data pricelist besar disimpan ke file (bukan SharedPreferences) |

### Keranjang & favorit

| Fitur | Deskripsi |
|-------|-----------|
| Keranjang | Qty, edit item, lanjut ke checkout |
| Favorit | Daftar produk favorit |

### Checkout & pesanan

| Fitur | Deskripsi |
|-------|-----------|
| Checkout | Dari keranjang atau **restore dari quotation** |
| Pelanggan | Nama, telepon, alamat; **Data Connect** (upsert / lookup by phone) |
| Wilayah | Picker wilayah Indonesia (API region) |
| Pengiriman & pembayaran | Metode/channel, bukti pembayaran (upload gambar) |
| Bonus & takeaway | Kontrol “bawa langsung”, perhitungan diskon & harga net |
| Order letter | Draft, approver, retry saat gagal |
| Sukses pesanan | Halaman konfirmasi setelah submit |
| Offline | Banner + retry saat tidak ada jaringan |

### Riwayat & pembayaran lanjutan

| Fitur | Deskripsi |
|-------|-----------|
| Riwayat pesanan | Daftar pesanan |
| Detail pesanan | Item, status, pembayaran, timeline approval |
| Tambah pembayaran | Dari detail pesanan (bottom sheet) |

### Quotation (penawaran)

| Fitur | Deskripsi |
|-------|-----------|
| Riwayat quotation | Daftar penawaran |
| PDF | Generate, preview, bagikan (pdf + printing + share_plus) |
| Edit pelanggan | Sheet edit data di alur quotation |

### Persetujuan (approval)

| Fitur | Deskripsi |
|-------|-----------|
| Inbox | Daftar menunggu persetujuan |
| Detail | Setuju / tolak dengan konteks lengkap |
| Deep link | `/approval_from_order/:orderId` — buka dari notifikasi/link |
| Lokasi | GPS + geocoding untuk konteks approval (dengan fallback aman) |

### Profil & bantuan

| Fitur | Deskripsi |
|-------|-----------|
| Profil | Info user, menu, statistik ringkas, versi app, logout |
| Pusat bantuan | FAQ / kontak (sesuai implementasi) |
| Telemetry debug | Hanya untuk user ID tertentu (halaman debug) |

### Notifikasi & tautan

| Fitur | Deskripsi |
|-------|-----------|
| FCM | Foreground, background, tap — navigasi ke fitur relevan |
| Notifikasi lokal | `flutter_local_notifications` |
| App Links | Deep link awal (`app_links`) + override `initialLocation` |

### Keandalan, update & keamanan

| Fitur | Deskripsi |
|-------|-----------|
| Crashlytics | Pelaporan error; filter error aset/jaringan transien |
| Analytics | Event lewat `AppAnalyticsService` + route observer |
| App Check | Play Integrity / App Attest (debug provider di dev) |
| Force update | Android: **in-app update** (native); iOS + fallback: **UpgradeAlert** |
| Konfigurasi | `.env` dev; **release: `--dart-define`** (lihat [Build release](#build-release--rahasia)) |

---

## Persyaratan

- Flutter SDK sesuai `pubspec.yaml` (Dart ^3.6.1)
- Toolchain Xcode (iOS) / Android Studio (Android)
- File `.env` untuk development (lihat Setup)
- Firebase: jalankan `flutterfire configure` setelah clone

---

## Setup

1. **Dependensi**
   ```bash
   flutter pub get
   ```

2. **Environment**
   - Salin `.env.example` → `.env` di root project
   - Minimal: `API_BASE_URL`, `CLIENT_ID`, `CLIENT_SECRET`
   - Opsional: Comforta, Region API, variabel Firebase di `.env.example` (server/CF); client memakai `firebase_options.dart`

3. **Firebase**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Menghasilkan `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`.

4. **Code generation** (setelah ubah freezed/json_serializable)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **iOS (Pods)** — setelah clone atau update native deps:
   ```bash
   cd ios && pod install && cd ..
   ```

---

## Menjalankan aplikasi

```bash
flutter run
```

Gunakan `-d <device_id>` untuk perangkat tertentu.

---

## Build release & rahasia

**Jangan** mengandalkan `.env` yang ikut ter-bundle untuk rahasia production. `AppConfig` membaca **`--dart-define` dulu**, lalu fallback `.env`.

**Disarankan:** script yang membaca variabel dari environment / `.env` lokal Anda dan memanggil Flutter dengan `--dart-define`:

```bash
# Pastikan .env terisi, lalu:
./scripts/build_release.sh appbundle   # AAB (Play Store)
./scripts/build_release.sh apk         # APK
```

Atau manual:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://... \
  --dart-define=CLIENT_ID=... \
  --dart-define=CLIENT_SECRET=...
```

| Kategori | Variabel | Wajib `--dart-define` di release? |
|----------|----------|-------------------------------------|
| Alita API | `API_BASE_URL`, `CLIENT_ID`, `CLIENT_SECRET` | Ya |
| Comforta | `COMFORTA_ACCESS_TOKEN`, `COMFORTA_CLIENT_ID`, `COMFORTA_CLIENT_SECRET` | Ya jika dipakai |
| Default di kode | `COMFORTA_API_HOST`, `REGION_API_BASE_URL` | Tidak |
| Firebase client | — | Pakai `firebase_options.dart`, bukan `.env` untuk app |

---

## Pengujian

```bash
flutter test
flutter test test/<path_ke_test>.dart

# Coverage + laporan HTML (perlu lcov: brew install lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

- Test memakai `dotenv.testLoad()` bila perlu kredensial inline
- **Aksesibilitas:** tombol icon-only punya `tooltip`; uji dengan text scale maksimum untuk alur login, detail produk, checkout

### Troubleshooting

| Masalah | Tindakan |
|---------|----------|
| `genhtml` tidak ditemukan | Install `lcov` |
| Konfigurasi API error | Pastikan `.env` berisi minimal tiga key Alita di atas |

---

## Arsitektur

| Lapisan | Pilihan |
|---------|---------|
| State | Riverpod (`StateNotifier`, `AsyncNotifier`, dll.) |
| Navigasi | GoRouter + `ShellRoute` (upgrade alert) |
| Struktur | **Feature-first** di `lib/features/` |

**Modul fitur:** `auth`, `cart`, `checkout`, `pricelist`, `approval`, `history`, `quotation`, `profile`, `favorites`, `product` (brand spec, dll.)

**Shared:** `lib/core/` — `config`, `services`, `theme`, `widgets`, `router`

### Path penting

| Tujuan | Path |
|--------|------|
| Konfigurasi | `lib/core/config/app_config.dart` |
| Router | `lib/core/router/app_router.dart` |
| Auth state | `lib/features/auth/logic/auth_provider.dart` |
| Fitur | `lib/features/<nama>/data/`, `logic/`, `presentation/` |
| Widget reusable | `lib/core/widgets/` |
| HTTP | `lib/core/services/api_client.dart` |
| Build release | `scripts/build_release.sh` |

---

## Referensi cepat

- Template env: `.env.example`
- Laporan coverage: `coverage/html/index.html` (setelah `flutter test --coverage`)
- Data Connect: [`docs/DATA_CONNECT.md`](docs/DATA_CONNECT.md)
- Deep link & App Links: [`docs/DEEPLINKS_SETUP.md`](docs/DEEPLINKS_SETUP.md)

---

## Dokumentasi internal

**FCM & lokasi persetujuan:** notifikasi memakai `type` + opsional `order_letter_id` untuk navigasi; POST `/order_letter_approves` mengirim `location` dan `lokasi_approval` dengan teks lokasi yang konsisten (alamat geocode atau fallback koordinat, bukan placeholder generik). Konfigurasi tautan aplikasi: [`docs/DEEPLINKS_SETUP.md`](docs/DEEPLINKS_SETUP.md).
