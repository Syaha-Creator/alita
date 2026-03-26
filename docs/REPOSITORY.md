# Repository & keamanan Git

Panduan singkat agar repo **Alita** tetap rapi dan aman setelah `main` menjadi cabang utama (hasil merge dari `clean-architecture-v2`).

## Cabang

| Branch | Peran |
|--------|--------|
| **`main`** | Sumber kebenaran — development & rilis terbaru |
| **`clean-architecture-v2`** | Boleh dipertahankan; isi sama dengan `main` setelah merge (bisa dihapus nanti jika tidak dipakai) |
| **`refactor`** | Riwayat / referensi; tidak perlu dihapus kecuali ingin bereskan daftar remote |

## Yang harus di GitHub (Settings → Branches)

Lakukan di **Settings → Branches → Branch protection rules** untuk **`main`**:

1. **Require a pull request before merging** — diskusi & diff terlihat; hindari push langsung ke `main` tanpa sengaja.
2. **Require status checks to pass** (jika nanti ada CI) — build/test wajib hijau.
3. **Do not allow bypassing** untuk peran non-admin (opsional).
4. **Include administrators** (opsional) — admin juga ikut aturan.

Tanpa akses GitHub API, langkah di atas hanya bisa Anda klik manual di web.

## Rahasia & file sensitif

- **Jangan commit** `.env` — sudah di `.gitignore`; gunakan `.env.example` sebagai template.
- **Release:** secrets lewat `--dart-define` / `./scripts/build_release.sh` (lihat README).
- Periksa berkala: `git log -p -- .env` tidak boleh pernah menampilkan isi rahasia (jika pernah ter-commit, rotate kredensial + `git filter-repo` / bantuan tim).

## Praktik kerja sehari-hari

```text
git checkout main
git pull origin main
git checkout -b feature/nama-fitur
# ... kerja ...
git push -u origin feature/nama-fitur
# buka Pull Request → main, merge setelah review
```

## Akun & akses

- Aktifkan **2FA** di GitHub untuk akun yang punya push ke repo.
- Batasi **Collaborators** hanya yang perlu akses tulis.

## Default branch

Pastikan **default branch** repository di GitHub = **`main`** (Settings → General → Default branch).
