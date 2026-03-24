# Firebase Cloud Functions (Alita Pricelist)

## Callable: `sendApprovalNotification`

Dipanggil dari aplikasi Flutter untuk mengirim FCM. Mendukung `type`:

- `next_approver` (default)
- `fully_approved`
- `rejected`
- `reminder` (bisa juga dari job terjadwal)

## Scheduled: `checkPendingApprovals`

Berjalan **setiap 1 jam** (timezone `Asia/Jakarta`, region `asia-southeast1`).

### Secrets wajib

```bash
firebase functions:secrets:set API_BASE_URL
firebase functions:secrets:set CLIENT_ID
firebase functions:secrets:set CLIENT_SECRET
firebase functions:secrets:set SCHEDULER_EMAIL
firebase functions:secrets:set SCHEDULER_PASSWORD
firebase functions:secrets:set APPROVER_USER_IDS
```

- `API_BASE_URL`: base URL API Ruby (sama seperti di app), tanpa trailing slash.
- `CLIENT_ID` / `CLIENT_SECRET`: pasangan OAuth yang valid untuk `POST /sign_in` (bisa sama dengan Android atau iOS).
- `SCHEDULER_EMAIL` / `SCHEDULER_PASSWORD`: **email + password akun yang boleh login** lewat `/sign_in`. Boleh akun admin Anda sendiri; tidak wajib user “service” terpisah. Untuk produksi, lebih aman pakai user khusus dengan hak minimal.
- `APPROVER_USER_IDS`: daftar **`user_id` approver** (sama konsep dengan `approver_id` di diskon / inbox) yang ingin diingatkan tiap jam — dipisah koma, mis. `12,34,56`. Job memanggil `GET /order_letter_approvals?user_id=<masing-masing>` lalu menghitung SP yang masih pending untuk user itu (logika mengikuti app).

### Login sekali per jalan job — perlu logout?

**Tidak ada logout.** Setiap kali Cloud Scheduler menjalankan `checkPendingApprovals` (mis. tiap jam), function:

1. `POST /sign_in` → dapat `access_token` (token hanya dipakai di dalam eksekusi itu).
2. Beberapa `GET` pakai token tersebut.
3. Selesai — tidak menyimpan sesi ke “disk” antar jalan.

Jadi **bukan** satu login untuk selamanya; **per eksekusi** ada satu kali sign-in (token baru). Itu normal dan menghindari token kedaluwarsa. Akun Anda di app HP **tidak** ikut “logout” karena ini request terpisah di server.

### Keamanan — jangan commit kredensial

- **Jangan** menaruh email/password di file proyek atau di Git.
- Set secret **hanya** lewat CLI atau Console (nilai tersimpan di Secret Manager):

```bash
firebase functions:secrets:set SCHEDULER_EMAIL
firebase functions:secrets:set SCHEDULER_PASSWORD
```

(Prompt akan meminta input; atau gunakan pipe dari lingkungan aman.)

- Jika password pernah tertulis di chat/email, **ganti password** akun tersebut di backend.

Jika `APPROVER_USER_IDS` kosong, job hanya log dan tidak mengirim apa pun.

### Secret Manager (wajib untuk `checkPendingApprovals`)

Functions v2 memakai `defineSecret`. Aktifkan API dulu di GCP:

- [Secret Manager API](https://console.developers.google.com/apis/api/secretmanager.googleapis.com/overview) untuk project Firebase Anda.

Setelah API aktif, buat secret (nilai tidak boleh kosong agar job bisa jalan):

```bash
echo -n "https://your-api.example.com" | firebase functions:secrets:set API_BASE_URL
echo -n "your_client_id" | firebase functions:secrets:set CLIENT_ID
echo -n "your_client_secret" | firebase functions:secrets:set CLIENT_SECRET
echo -n "scheduler@example.com" | firebase functions:secrets:set SCHEDULER_EMAIL
echo -n "your_password" | firebase functions:secrets:set SCHEDULER_PASSWORD
echo -n "12,34,56" | firebase functions:secrets:set APPROVER_USER_IDS
```

### Deploy

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

Butuh project Firebase pada paket **Blaze** agar Cloud Scheduler + Functions v2 berjalan.

Callable `sendApprovalNotification` (v1) tetap bisa di-deploy; jika deploy gagal hanya karena secret, aktifkan Secret Manager lalu jalankan ulang `firebase deploy --only functions`.
