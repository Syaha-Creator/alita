# Firebase Data Connect — Pelanggan Global

## Tujuan

Database pelanggan global di **PostgreSQL** (Cloud SQL) via **Firebase Data Connect**.
Semua sales dapat **membaca** (cari by HP) dan **menulis** (upsert setelah transaksi) data kontak pelanggan — omnichannel, terpisah dari buku kontak lokal di device masing-masing.

---

## Infrastruktur

| Property | Nilai |
|---|---|
| GCP Project | `alita-pricelist-12d76` |
| Region | `asia-southeast1` (Singapore) |
| Service ID | `alita-service` |
| Cloud SQL Instance | `alita-db-instance` |
| Database | `alitadb` |
| Connector ID | `alita-connector` |

---

## Struktur File

```
dataconnect/
├── dataconnect.yaml          # Konfigurasi service, location, Cloud SQL
├── schema/
│   └── schema.gql            # Tipe Customer → tabel PostgreSQL
└── connector/
    ├── connector.yaml         # connectorId + output SDK Dart
    ├── queries.gql            # GetCustomerByPhone
    └── mutations.gql          # UpsertCustomer

lib/features/checkout/
├── data/
│   ├── dataconnect/generated/ # SDK auto-generated (jangan edit manual)
│   │   ├── alita_connector.dart
│   │   ├── get_customer_by_phone.dart
│   │   └── upsert_customer.dart
│   ├── models/
│   │   └── customer_model.dart
│   └── services/
│       └── customer_repository.dart
└── logic/
    └── customer_repository_provider.dart
```

---

## Skema Data

Primary key: `phoneNumber` (nomor HP ternormalisasi, prefiks `62`).

```graphql
type Customer @table(key: ["phoneNumber"]) {
  phoneNumber: String!   # PK — mis. "628123456789"
  name:        String!
  email:       String
  region:      String    # Wilayah / area sales
  address:     String    # Alamat lengkap
  provinsi:    String
  kota:        String
  kecamatan:   String
}
```

---

## Operasi GraphQL

### Query — `GetCustomerByPhone`

```graphql
query GetCustomerByPhone($phoneNumber: String!)
  @auth(level: USER) {
  customer(key: { phoneNumber: $phoneNumber }) {
    phoneNumber name email region address provinsi kota kecamatan
  }
}
```

### Mutation — `UpsertCustomer`

```graphql
mutation UpsertCustomer(
  $phoneNumber: String!  $name: String!
  $email: String  $region: String  $address: String
  $provinsi: String  $kota: String  $kecamatan: String
) @auth(level: USER) {
  customer_upsert(data: { phoneNumber, name, email, region, address, provinsi, kota, kecamatan })
}
```

Keduanya menggunakan `@auth(level: USER)` — setiap user Firebase yang terautentikasi (termasuk anonymous) boleh memanggil.

---

## Keamanan & Autentikasi

- Query/mutation memakai `@auth(level: USER)` — cukup **user Firebase apa pun yang terautentikasi**, termasuk **Anonymous** (bukan “harus email/password”).
- Di app, setelah **login API Alita sukses** (atau restore sesi), `AuthNotifier._initFirebaseAnonymousForDataConnect()` memanggil `signOut` lalu `signInAnonymously()` agar ada **ID token** untuk Data Connect.
- **Prasyarat:** **Anonymous** harus **enabled** di Firebase Console → Authentication → Sign-in providers (screenshot Anda sudah menunjukkan user anonim terbuat — bagus).

### App Check (penyebab #1 “lookup cloud selalu error”)

Di `main.dart`, **Firebase App Check** diaktifkan sebelum app jalan. Data Connect di backend sering **memaksa App Check**. Kalau token tidak valid, SDK melempar exception → di checkout muncul pesan gagal (bukan “tidak ditemukan”).

| Mode build | Provider | Yang harus dilakukan |
|------------|----------|----------------------|
| Debug / Profile | `AndroidProvider.debug` / `AppleProvider.debug` | Ambil **debug token** dari logcat / Xcode, lalu **daftarkan** di Firebase Console → App Check → Apps → Manage debug tokens. Tanpa ini, request Data Connect ditolak. |
| Release | Play Integrity / DeviceCheck | Pastikan app terdaftar benar (SHA-256 release, dsb.). |

**Console:** App Check → pastikan produk **Data Connect** / API terkait tidak dalam state yang memblokir app Anda, atau coba **monitor** request ditolak.

### Membedakan “error” vs “kosong”

- **Tabel `customers` kosong** di Explorer = `GetCustomerByPhone` tetap **sukses** dengan `customer == null`. Itu **bukan** exception; setelah perbaikan UX, app menampilkan info “belum ada di cloud”.
- **Metric “Network sent bytes: 0”** di dashboard kadang tidak mencerminkan payload GraphQL ke klien; jangan hanya mengandalkan angka itu untuk menyimpulkan gagal.

---

## Flow End-to-End

### A. Startup → Siap pakai Data Connect

```
App start
  │
  ├── Firebase.initializeApp()
  ├── App Check activate (debug / Play Integrity / DeviceCheck)
  │
  ├── Login API Alita sukses (atau sesi dipulihkan)
  └── signInAnonymously()  ← ID token untuk @auth(USER)
```

### B. Sales cari pelanggan di cloud (checkout)

```
┌──────────────────────────────────────────────────────┐
│  Checkout Page — field "No. HP Utama"                │
│  [ 0812xxxxxxx ]  [☁️]                               │
└──────────────────┬───────────────────────────────────┘
                   │ tap ikon cloud
                   ▼
          normalizePhoneKey("0812...") → "6281..."
                   │
                   ▼
     CustomerRepository.getCustomerByPhone("6281...")
                   │
                   ▼
   ┌───── Data Connect (GetCustomerByPhone) ──────┐
   │              PostgreSQL                       │
   └──────────────────┬───────────────────────────┘
                      │
              ┌───────┴────────┐
              │ Ditemukan?     │
              ├── Ya ──────────┤
              │  Auto-fill:    │ Snackbar: "Data ditemukan"
              │  nama, email,  │
              │  wilayah,      │
              │  alamat, prov, │
              │  kota, kec     │
              ├── Tidak ───────┤
              │  Form tetap    │ Snackbar info: belum ada di cloud
              │  manual        │
              └────────────────┘
```

### C. Setelah Surat Pesanan berhasil

```
Submit checkout (API Alita)
  │
  ├── Semua detail SP berhasil dikirim
  │
  ├── [Foreground] Simpan ke buku kontak lokal (jika checkbox aktif)
  │
  └── [Background] CustomerRepository.upsertFromCheckoutContactMapQuiet()
         │
         ▼
    UpsertCustomer mutation → PostgreSQL
    (unawaited — tidak blok UI, error hanya di-log)
```

### D. Lokal vs Cloud — independen

```
┌─────────── Lokal ────────────┐   ┌────────── Cloud ──────────────┐
│ Pilih Kontak device          │   │ Cari di cloud (ikon ☁️)       │
│ Checkbox "Simpan ke buku"    │   │ Upsert otomatis setelah SP OK │
│                              │   │                                │
│ → Buku kontak HP sales       │   │ → PostgreSQL (semua sales)     │
└──────────────────────────────┘   └────────────────────────────────┘
        Keduanya mengisi form yang sama, tetapi sumber datanya terpisah.
```

---

## Dart — Penggunaan di App

### CustomerModel

```dart
class CustomerModel {
  final String phoneNormalized; // PK: "62..."
  final String name;
  final String email;
  final String region;
  final String address;
  final String? provinsi;
  final String? kota;
  final String? kecamatan;
}
```

### CustomerRepository (ringkasan API)

| Method | Kegunaan |
|---|---|
| `normalizePhoneKey(raw)` | `"0812..."` → `"6281..."` |
| `getCustomerByPhone(phone)` | Query → `CustomerModel?` |
| `upsertCustomer(model)` | Insert atau update ke PostgreSQL |
| `upsertFromCheckoutContactMap(map)` | Bangun model dari map checkout lalu upsert |
| `upsertFromCheckoutContactMapQuiet(repo, map)` | Sama, tapi error hanya di-log (untuk background call) |

### Provider (Riverpod)

```dart
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});
```

---

## Perintah CLI

| Perintah | Kegunaan |
|---|---|
| `firebase deploy --only dataconnect` | Deploy skema + connector ke GCP |
| `firebase dataconnect:sql:migrate` | Migrasi tabel PostgreSQL jika skema berubah |
| `firebase dataconnect:sdk:generate` | Regenerate Dart SDK (dari root project) |
| `firebase deploy --only dataconnect --force` | Deploy dengan breaking change |

> **Catatan:** Setelah `sdk:generate`, file di `generated/` mungkin perlu disesuaikan format/linter ignore. Jangan edit generated files secara manual di luar itu.

---

## Troubleshooting

| Masalah | Solusi |
|---|---|
| `connector_id must use DNS characters` | Gunakan lowercase + hyphen: `alita-connector` |
| `instanceId` ditolak API | Isi hanya nama instance (`alita-db-instance`), bukan `project:region:instance` |
| Mutation error subfield | `customer_upsert` return scalar — jangan tambah `{ key { ... } }` |
| `@auth` deploy ditolak | Tambah `insecureReason: "..."` di directive, atau deploy dengan `--force` |
| Tabel belum ada di DB | Jalankan `firebase dataconnect:sql:migrate` |
| SDK generate ke path salah | Periksa `outputDir` di `connector.yaml` — harus relatif dari folder connector |
| Anonymous auth gagal | Pastikan Anonymous provider **enabled** di Firebase Console |
| Lookup cloud **selalu** pesan gagal (bukan “belum ada data”) | Hampir selalu **App Check**: daftarkan **debug token** (debug/profile) atau perbaiki Play Integrity / bundle id (release). Lihat log debug: snackbar menyertakan `Exception` di `kDebugMode`. |
| Tabel kosong tapi tidak ada error | Normal — upsert baru jalan setelah **checkout sukses** (dan nama + HP valid di payload). |
