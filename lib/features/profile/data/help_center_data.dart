import 'package:flutter/material.dart';

/// Static FAQ content for the Help Center.
///
/// Kept separate from the UI so the page file stays focused on presentation.
class FaqSection {
  final String title;
  final IconData icon;
  final List<FaqItem> items;

  const FaqSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

class FaqItem {
  final String q;
  final String a;

  const FaqItem({required this.q, required this.a});
}

class FlatFaq {
  final int sectionIndex;
  final int itemIndex;
  final String sectionTitle;
  final IconData sectionIcon;
  final FaqItem item;

  const FlatFaq({
    required this.sectionIndex,
    required this.itemIndex,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.item,
  });
}

const helpCenterSections = <FaqSection>[
  FaqSection(
    title: 'Akun & Akses',
    icon: Icons.lock_person_rounded,
    items: [
      FaqItem(
        q: 'Tidak bisa login / stuck di loading?',
        a: 'Pastikan internet stabil, lalu tutup aplikasi dan buka kembali. '
            'Jika masih bermasalah, coba logout lalu login ulang. '
            'Pesan "Email atau Password salah" berarti kredensial tidak cocok — cek ulang atau hubungi admin.',
      ),
      FaqItem(
        q: 'Muncul "Terjadi masalah pada server"?',
        a: 'Server pusat sedang bermasalah (maintenance/gangguan). '
            'Tunggu beberapa menit lalu coba lagi. Jika berlanjut lebih dari 30 menit, hubungi admin IT.',
      ),
      FaqItem(
        q: 'Data profil/area tidak sesuai?',
        a: 'Tarik layar ke bawah (Swipe to Refresh) agar data terbaru terambil. '
            'Jika tetap tidak sesuai, kemungkinan data pusat belum diperbarui — konfirmasi ke admin.',
      ),
    ],
  ),
  FaqSection(
    title: 'Produk & Katalog',
    icon: Icons.inventory_2_rounded,
    items: [
      FaqItem(
        q: 'Daftar produk kosong / "Pilih Channel & Brand"?',
        a: 'Pilih Channel (S0/S1/MM) dan Brand di filter atas terlebih dahulu. '
            'Jika tetap kosong, katalog untuk kombinasi itu belum tersedia — coba brand/channel lain.',
      ),
      FaqItem(
        q: 'Apa bedanya Tunggal dan Full Set?',
        a: 'Tunggal = hanya kasur/mattress saja.\n'
            'Full Set = kasur + divan + headboard (+ sorong jika ada).\n'
            'Harga Full Set dihitung dari total komponen.',
      ),
      FaqItem(
        q: 'Kenapa harus pilih warna/kain dulu?',
        a: 'Warna dan kain menentukan SKU (kode barang) untuk pabrik. '
            'Tanpa info ini, pesanan tidak bisa diproses.',
      ),
      FaqItem(
        q: 'Harga berubah saat ganti model sandaran/divan?',
        a: 'Setiap model memiliki harga berbeda. '
            'Harga EUP otomatis menyesuaikan saat Anda mengganti pilihan.',
      ),
      FaqItem(
        q: '"Harga disesuaikan ke nilai minimum"?',
        a: 'Harga yang dimasukkan lebih rendah dari batas minimum. '
            'Sistem otomatis menyesuaikan agar tidak di bawah ketentuan.',
      ),
    ],
  ),
  FaqSection(
    title: 'Diskon & Harga',
    icon: Icons.percent_rounded,
    items: [
      FaqItem(
        q: 'Bagaimana cara memberikan diskon?',
        a: 'Di halaman detail produk, ketuk tombol "Diskon" untuk membuka modal diskon. '
            'Masukkan persentase (Disc 1 s/d Disc 4). Harga dihitung bertingkat (cascading).',
      ),
      FaqItem(
        q: 'Apa itu diskon bertingkat (Disc 1–4)?',
        a: 'Diskon dihitung berurutan, bukan dijumlahkan.\n'
            'Contoh: Harga Rp1.000.000\n'
            '• Disc 1 = 10% → Rp900.000\n'
            '• Disc 2 = 5% → Rp855.000\n'
            'Disc 3 memerlukan persetujuan Manager.',
      ),
      FaqItem(
        q: '"Tidak ada alokasi diskon"?',
        a: 'Produk tidak memiliki slot diskon dari sistem pusat. '
            'Hubungi atasan/admin untuk memeriksa alokasi.',
      ),
      FaqItem(
        q: 'Kenapa perlu persetujuan Manager?',
        a: 'Jika mengisi Disc 3, pesanan otomatis memerlukan persetujuan Manager selain SPV. '
            'Ini kebijakan untuk diskon di atas level tertentu.',
      ),
    ],
  ),
  FaqSection(
    title: 'Keranjang & Checkout',
    icon: Icons.shopping_cart_checkout_rounded,
    items: [
      FaqItem(
        q: 'Item keranjang tidak sesuai?',
        a: 'Pastikan menekan "Tambah ke Keranjang" setelah memilih varian (ukuran/warna/komponen). '
            'Jika tetap salah, hapus item lalu tambahkan ulang.',
      ),
      FaqItem(
        q: '"Lengkapi field wajib di bagian ..."?',
        a: 'Ada kolom yang belum diisi di bagian yang disebutkan. '
            'Layar otomatis scroll ke sana. Kolom wajib ditandai bintang (*).',
      ),
      FaqItem(
        q: 'Apa bedanya Lunas dan DP?',
        a: 'Lunas = bayar seluruh total di muka (nominal otomatis terisi).\n'
            'DP = bayar sebagian (minimal 30% dari total), sisanya nanti.',
      ),
      FaqItem(
        q: 'Cara bayar dengan 2 metode (split payment)?',
        a: 'Di bagian Informasi Pembayaran, ketuk "+ Tambah" di kanan header. '
            'Isi nominal & metode masing-masing. Jika total = harga pesanan, otomatis Lunas.',
      ),
      FaqItem(
        q: 'Kurir Pabrik vs Bawa Sendiri?',
        a: 'Kurir Pabrik = dikirim pabrik ke alamat pelanggan (bisa ada ongkir).\n'
            'Bawa Sendiri = ambil langsung (tanpa ongkir, bertanda "TAKE AWAY").',
      ),
      FaqItem(
        q: 'Kenapa harus pilih SPV dan Manager?',
        a: 'Setiap pesanan perlu persetujuan SPV. Jika ada Disc 3, Manager juga wajib dipilih. '
            'Pesanan tidak bisa disubmit tanpa approver.',
      ),
      FaqItem(
        q: '"Sebagian Barang Gagal" setelah submit?',
        a: 'SP sudah dibuat, tapi beberapa item gagal masuk ke server. '
            'Tekan "Coba Lagi Kirim Barang Gagal" untuk kirim ulang tanpa membuat SP baru.',
      ),
      FaqItem(
        q: 'Daftar approver kosong atau error?',
        a: 'Tekan "Coba Lagi" di section Persetujuan. Pastikan internet stabil. '
            'Jika masih kosong, hubungi admin — area Anda mungkin belum punya approver.',
      ),
      FaqItem(
        q: 'Validasi email/no. HP gagal?',
        a: 'Email harus mengandung @ dan domain (contoh: nama@email.com).\n'
            'No. HP harus 10–15 digit angka, tanpa huruf.',
      ),
    ],
  ),
  FaqSection(
    title: 'Penawaran Harga',
    icon: Icons.request_quote_rounded,
    items: [
      FaqItem(
        q: 'Apa itu Penawaran Harga (Quotation)?',
        a: 'Draft harga sementara dalam bentuk PDF yang bisa dikirim ke pelanggan sebelum pesanan resmi. '
            'Data tersimpan di HP (offline), bukan di server.',
      ),
      FaqItem(
        q: 'Cara membuat penawaran?',
        a: 'Tambahkan produk ke keranjang → buka Checkout → ketuk ikon ⋮ di kanan atas → '
            '"Simpan Penawaran (PDF)". PDF otomatis dibuat dan bisa dikirim via WhatsApp.',
      ),
      FaqItem(
        q: 'Cara ubah penawaran jadi pesanan resmi?',
        a: 'Buka Riwayat Penawaran (menu Profil) → cari draft → ketuk "Lanjutkan Transaksi". '
            'Item akan dimuat ke Checkout untuk dilengkapi dan disubmit.',
      ),
      FaqItem(
        q: 'Bisa edit data pelanggan di penawaran?',
        a: 'Ya, di Riwayat Penawaran ketuk ikon pensil pada kartu penawaran untuk edit.',
      ),
      FaqItem(
        q: 'Penawaran hilang setelah ganti HP?',
        a: 'Data disimpan lokal di HP. Ganti HP / install ulang akan menghapus draft. '
            'Simpan PDF-nya sebagai cadangan.',
      ),
    ],
  ),
  FaqSection(
    title: 'Riwayat Pesanan',
    icon: Icons.receipt_long_rounded,
    items: [
      FaqItem(
        q: 'Apa arti status pesanan?',
        a: '• Pending = menunggu persetujuan atasan\n'
            '• Approved = disetujui, siap diproses pabrik\n'
            '• Rejected = ditolak, SP dibatalkan\n'
            'Tarik layar ke bawah untuk status terbaru.',
      ),
      FaqItem(
        q: 'Pesanan masih Pending lama?',
        a: 'Menunggu approval dari SPV (dan Manager jika ada Disc 3). '
            'Hubungi atasan untuk mempercepat.',
      ),
      FaqItem(
        q: 'Cara tambah pembayaran di pesanan lama?',
        a: 'Buka detail pesanan → ketuk "Tambah Pembayaran" di bawah → isi nominal, metode, upload bukti.',
      ),
      FaqItem(
        q: '"Gagal memuat data" / detail error?',
        a: 'Pastikan internet stabil. "User ID tidak ditemukan" = logout dan login ulang. '
            '"Gagal memproses data" = server bermasalah, coba lagi nanti.',
      ),
      FaqItem(
        q: 'Riwayat kosong / "Belum ada pesanan"?',
        a: 'Pastikan rentang tanggal filter sesuai. Tarik ke bawah untuk refresh.',
      ),
    ],
  ),
  FaqSection(
    title: 'Approval & Persetujuan',
    icon: Icons.verified_user_rounded,
    items: [
      FaqItem(
        q: 'Atasan belum dapat notifikasi?',
        a: 'Pastikan internet stabil. Atasan bisa buka Persetujuan Diskon → Swipe to Refresh.',
      ),
      FaqItem(
        q: 'Inbox Approval kosong?',
        a: 'Coba Swipe to Refresh. Pastikan akun punya hak Approver. '
            'Jika masih kosong, role belum aktif — hubungi admin.',
      ),
      FaqItem(
        q: 'Kenapa GPS harus aktif saat approve?',
        a: 'Sistem mencatat lokasi sebagai verifikasi. Aktifkan GPS mode Akurasi Tinggi sebelum Setujui/Tolak.',
      ),
      FaqItem(
        q: 'Diskon ditolak, lalu apa?',
        a: 'SP dibatalkan (Rejected). Sales perlu buat pesanan baru dengan diskon berbeda.',
      ),
      FaqItem(
        q: 'Notifikasi tidak masuk sama sekali?',
        a: 'Cek izin notifikasi di Pengaturan HP. Pastikan Hemat Baterai tidak membatasi aplikasi.',
      ),
    ],
  ),
  FaqSection(
    title: 'Favorit',
    icon: Icons.favorite_rounded,
    items: [
      FaqItem(
        q: 'Cara menambahkan produk ke favorit?',
        a: 'Di halaman detail produk, ketuk ikon hati (♡) di kanan atas. '
            'Produk tersimpan di halaman Favorit pada navigation bar.',
      ),
      FaqItem(
        q: 'Favorit hilang setelah ganti HP?',
        a: 'Data favorit disimpan lokal. Logout, install ulang, atau ganti perangkat akan menghapusnya.',
      ),
    ],
  ),
  FaqSection(
    title: 'Upload Bukti & Foto',
    icon: Icons.camera_alt_rounded,
    items: [
      FaqItem(
        q: 'Gagal upload foto bukti transfer?',
        a: 'Pastikan izin Kamera & Galeri aktif di Pengaturan HP. '
            '"Gagal mengambil gambar" = izin belum diberikan.',
      ),
      FaqItem(
        q: 'Foto dipilih tapi tidak terkirim?',
        a: 'Koneksi tidak stabil atau ukuran file besar. Coba foto lain yang lebih kecil.',
      ),
      FaqItem(
        q: 'Setiap pembayaran perlu bukti sendiri?',
        a: 'Ya. Jika split payment (2 pembayaran), masing-masing harus upload bukti transfer.',
      ),
    ],
  ),
  FaqSection(
    title: 'PDF & Dokumen',
    icon: Icons.picture_as_pdf_rounded,
    items: [
      FaqItem(
        q: 'PDF tidak bisa dibuka atau kosong?',
        a: 'Ulangi generate saat koneksi stabil. Jika masih error, tutup dan buka kembali aplikasi.',
      ),
      FaqItem(
        q: 'Beda PDF Surat Pesanan vs Penawaran?',
        a: 'SP = dokumen resmi di sistem.\n'
            'Penawaran = draft sementara bertuliskan "QUOTATION" dengan disclaimer harga bisa berubah.',
      ),
      FaqItem(
        q: 'Cara kirim PDF via WhatsApp?',
        a: 'Setelah PDF dibuat, pilih Share → WhatsApp. '
            'Bisa juga kirim ulang dari Riwayat Penawaran atau Detail Pesanan.',
      ),
    ],
  ),
  FaqSection(
    title: 'Koneksi & Error',
    icon: Icons.wifi_off_rounded,
    items: [
      FaqItem(
        q: 'Aplikasi lambat / tidak memuat data?',
        a: 'Cek jaringan dan coba pindah Wi‑Fi/seluler. '
            'Swipe to Refresh pada halaman bermasalah, atau tutup dan buka kembali aplikasi.',
      ),
      FaqItem(
        q: '"Periksa koneksi internet" padahal lancar?',
        a: 'Jaringan aktif tapi koneksi ke server terputus. '
            'Coba matikan dan nyalakan ulang Wi‑Fi/Data, atau coba jaringan lain.',
      ),
      FaqItem(
        q: 'Muncul error teknis panjang?',
        a: 'Masalah sementara di server/koneksi. Screenshot pesan error-nya, coba lagi. '
            'Jika berulang, kirim screenshot ke admin IT.',
      ),
    ],
  ),
  FaqSection(
    title: 'Check-in & Lokasi',
    icon: Icons.location_on_rounded,
    items: [
      FaqItem(
        q: '"Work Place Tidak Ditemukan"?',
        a: 'Pastikan GPS Akurasi Tinggi menyala. '
            'Di dalam gedung, coba keluar sejenak agar satelit terbaca.',
      ),
      FaqItem(
        q: 'Lokasi aktif tapi meleset?',
        a: 'Pastikan mode Lokasi "Akurasi Tinggi" (bukan Hemat Daya). '
            'Di indoor, coba dekat jendela/area terbuka.',
      ),
    ],
  ),
  FaqSection(
    title: 'Update Aplikasi',
    icon: Icons.system_update_rounded,
    items: [
      FaqItem(
        q: 'Diminta update dan tidak bisa lanjut?',
        a: 'Itu Force Update agar fitur selalu terbaru. '
            'Update melalui Play Store/App Store, lalu buka kembali.',
      ),
      FaqItem(
        q: 'Sudah update tapi versi lama?',
        a: 'Force close aplikasi lalu buka kembali. '
            'Cek versi di menu Profil → Tentang Aplikasi.',
      ),
    ],
  ),
];
