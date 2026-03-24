# Setup Deep Links (Firebase Hosting)

Deep links memungkinkan link seperti `https://alita-pricelist-12d76.web.app/product/123` dibuka langsung di aplikasi Alita Pricelist.

## 1. Deploy Firebase Hosting

```bash
firebase deploy --only hosting
```

URL hosting: `https://alita-pricelist-12d76.web.app`

## 2. Android: SHA256 Fingerprint (PENTING)

Agar App Links berjalan, Anda **harus** mengisi SHA256 fingerprint di `hosting/.well-known/assetlinks.json`.

### Cara mendapatkan fingerprint

**Untuk build release / Play Store:**

1. Buka [Play Console](https://play.google.com/console) → App → Setup → App signing
2. Copy **SHA-256 certificate fingerprint** (format: `AA:BB:CC:DD:...`)
3. Atau dari keystore lokal:
   ```bash
   keytool -list -v -keystore path/to/your-release.keystore -alias your-alias
   ```
   Cari baris **SHA256:** dan copy nilainya.

**Untuk debug (testing):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

### Update assetlinks.json

Edit `hosting/.well-known/assetlinks.json` — ganti `REPLACE_WITH_YOUR_SHA256_FINGERPRINT` dengan fingerprint Anda. Untuk beberapa environment (debug + release), tambahkan keduanya:

```json
"sha256_cert_fingerprints": [
  "AA:BB:CC:DD:...(release)",
  "EE:FF:GG:HH:...(debug)"
]
```

Lalu deploy lagi: `firebase deploy --only hosting`

## 3. Verifikasi

### Android

1. Install app (release atau debug)
2. Tunggu ~20 detik
3. Jalankan:
   ```bash
   adb shell pm get-app-links com.syahrul.alitapricelist.alitapricelist
   ```
   Cek apakah domain `alita-pricelist-12d76.web.app` statusnya `verified`

4. Test: kirim link `https://alita-pricelist-12d76.web.app/product/123` ke diri sendiri via WhatsApp, ketuk link → harus buka app

### iOS

1. Pastikan **Associated Domains** capability sudah aktif di Apple Developer Portal
2. Test: buka link dari Notes atau Safari → harus tawarkan "Open in Alita Pricelist"

## 4. Troubleshooting

- **Android: verified = none** → Pastikan sha256 di assetlinks.json sesuai dengan signing key yang dipakai (Play App Signing atau upload key)
- **iOS: link buka Safari** → Cek AASA di `https://alita-pricelist-12d76.web.app/.well-known/apple-app-site-association` — harus valid JSON
- **Produk tidak ditemukan** → User harus login dulu dan product list sudah dimuat (area/channel terpilih)
