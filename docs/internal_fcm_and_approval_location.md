# Dokumentasi internal: FCM persetujuan & lokasi API

## Payload data FCM (alur notifikasi)

Field `data` pada pesan FCM memakai **`type`** untuk routing di app (`NotificationHandlerService`). **`order_letter_id`** (numeric, string di payload) dipakai bila tidak ada JSON order lengkap di payload: misalnya **`next_approver`** dan **`fully_approved` / `rejected`** membuka layar yang memuat SP dari API dengan ID tersebut. Tanpa `order_letter_id`, app fallback ke inbox atau riwayat pesanan. Tipe lain (`reminder`, `approval_inbox`, dll.) dan detail Cloud Function + secrets ada di [`functions/README.md`](../functions/README.md).

## `location` vs `lokasi_approval` (POST `/order_letter_approves` & PUT diskon)

Keduanya diisi **string yang sama** hasil client: alamat dari reverse geocoding (GPS + `geocoding`) jika tersedia; jika geocoder kosong atau timeout tetapi koordinat ada, dipakai teks **`Koordinat {lat},{lng}`**; hanya jika benar-benar tidak ada data dipakai **`Lokasi tidak terdeteksi`**. Field **`latitude` / `longitude`** tetap dikirim bila GPS berhasil. Perilaku ini menggantikan hardcode lama `location: "Lokasi terdeteksi via sistem"` agar server dan laporan mencerminkan lokasi aktual. Jika backend mengharapkan `location` sebagai enum terpisah dari teks alamat, kontrak API perlu diselaraskan di sisi Rails.

## Telemetry lokasi persetujuan

Event **`approval_location_resolved`** (lihat log / Crashlytics di release) memuat **`kind`**: `geocoded_address` (alamat dari geocoder), `coordinate_fallback` (hanya koordinat teks), atau `unknown` — berguna membandingkan emulator vs perangkat nyata.

## HTTP 401 / 403 saat persetujuan

API Alita memakai **`access_token`** di query; aplikasi **tidak** melakukan refresh token otomatis. Jika sesi kedaluwarsa atau dicabut, endpoint persetujuan (`order_letter_approves`, `order_letter_discounts`, `order_letters`, `order_letter_approvals`) dapat mengembalikan **401** atau **403**. Client menangkap itu sebagai **`ApiSessionExpiredException`**: pesan ramah ke user, telemetry **`approval_session_expired`** / **`approval_inbox_auth`**, lalu **logout** agar user login ulang dengan token segar. Jika 401 masih sering di device nyata, periksa TTL token di server atau pertimbangkan endpoint refresh jika tersedia.
