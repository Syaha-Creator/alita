# 📦 Alita Pricelist - Integration Guide

## 🎯 Cara Menggunakan Context ini di Window Cursor Lain

### Langkah 1: Copy File Rules

Copy file berikut ke aplikasi utama Anda:

```bash
# Copy file context ke aplikasi utama
cp .cursor/rules/alita_pricelist_context.mdc /path/to/aplikasi_utama/.cursor/rules/
```

Atau secara manual:
1. Buka folder `.cursor/rules/` di aplikasi utama (buat jika belum ada)
2. Copy file `alita_pricelist_context.mdc` dari project ini ke sana

### Langkah 2: Verifikasi

Setelah di-copy, AI di window Cursor aplikasi utama akan **otomatis memahami** struktur dan konteks dari `alita_pricelist` project ini.

## 📋 Apa yang Akan AI Ketahui?

Setelah file context di-copy, AI akan memahami:

✅ **Struktur lengkap** project alita_pricelist  
✅ **Semua fitur** yang ada (authentication, product, cart, checkout, approval)  
✅ **Dependencies** yang digunakan  
✅ **Cara integrasi** dengan aplikasi lain  
✅ **Routes, Storage Keys, Constants**  
✅ **Pattern & Best Practices** yang digunakan  
✅ **Important Notes** untuk menghindari konflik  

## 🔗 Integrasi sebagai Dependency

### 1. Tambahkan Path Dependency

Di `pubspec.yaml` aplikasi utama:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... dependencies lain ...
  
  alitapricelist:
    path: ../alita_pricelist  # Sesuaikan path relatif
```

### 2. Import & Gunakan

```dart
import 'package:alitapricelist/features/product/presentation/pages/product_page.dart';
import 'package:alitapricelist/features/cart/presentation/bloc/cart_bloc.dart';
```

### 3. Initialize DI

```dart
import 'package:alitapricelist/config/dependency_injection.dart' as pricelist_di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Init aplikasi utama
  await initMainAppDependencies();
  
  // Init alita_pricelist DI
  await pricelist_di.initDependencies();
  
  runApp(MyApp());
}
```

## ⚠️ Catatan Penting

1. **Jangan ubah struktur internal** alita_pricelist jika masih digunakan standalone
2. **Cek duplikasi GetIt** - gunakan `getIt.isRegistered<T>()` sebelum register
3. **Firebase hanya init sekali** - di aplikasi utama saja
4. **Copy assets** - fonts, images, logos perlu di-copy juga
5. **Setup .env** - pastikan credentials ada

## 🆘 Troubleshooting

### Error: "Target of URI doesn't exist"
- Pastikan path dependency benar di `pubspec.yaml`
- Run `flutter pub get`

### Error: "GetIt: Service already registered"
- Cek duplikasi registrasi
- Gunakan namespace terpisah untuk DI

### Error: "Firebase already initialized"
- Hapus Firebase init dari alita_pricelist
- Init hanya di aplikasi utama

---

**File ini dibuat untuk membantu integrasi alita_pricelist ke aplikasi lain tanpa merusak struktur yang sudah ada.**

