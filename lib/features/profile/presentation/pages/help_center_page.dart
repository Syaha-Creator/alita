import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final sections = const <_FaqSection>[
      _FaqSection(
        title: 'Akun & Akses',
        items: [
          _FaqItem(
            q: 'Tidak bisa login / stuck di loading, apa yang harus dilakukan?',
            a: 'Pastikan internet stabil, lalu tutup aplikasi dan buka kembali. '
                'Jika masih bermasalah, coba logout lalu login ulang (jika tombol tersedia), atau hubungi admin untuk reset akses.',
          ),
          _FaqItem(
            q: 'Kenapa data profil/area tidak sesuai?',
            a: 'Tarik layar ke bawah (Swipe to Refresh) pada halaman terkait agar data terbaru terambil. '
                'Jika tetap tidak sesuai, kemungkinan data pusat belum diperbarui—konfirmasi ke admin/atasan.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Check-in & Lokasi',
        items: [
          _FaqItem(
            q: 'Kenapa saat check-in muncul "Work Place Tidak Ditemukan"?',
            a: 'Pastikan GPS/Lokasi menyala dengan mode Akurasi Tinggi. '
                'Jika di dalam gedung, coba keluar sejenak agar satelit terbaca, lalu refresh.',
          ),
          _FaqItem(
            q: 'Lokasi sudah aktif tapi hasilnya meleset/akurasi jelek, kenapa?',
            a: 'Pastikan mode Lokasi “Akurasi Tinggi” aktif dan tidak sedang di mode Hemat Daya. '
                'Di area indoor, akurasi bisa turun—coba dekat jendela/area terbuka lalu ulangi.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Koneksi & Sinkronisasi',
        items: [
          _FaqItem(
            q: 'Aplikasi terasa lambat atau tidak memuat data, apa solusinya?',
            a: 'Cek jaringan (Wi‑Fi/seluler) dan coba pindah jaringan. '
                'Lakukan Swipe to Refresh pada halaman yang bermasalah. Jika masih lambat, tutup aplikasi dan buka kembali.',
          ),
          _FaqItem(
            q: 'Kenapa data katalog/pricelist belum berubah padahal sudah update?',
            a: 'Terkadang cache masih tersimpan. Coba Swipe to Refresh di daftar produk. '
                'Jika masih sama, tunggu beberapa saat—update katalog pusat bisa bertahap.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Keranjang & Checkout',
        items: [
          _FaqItem(
            q: 'Kenapa item di keranjang tidak sesuai setelah kembali dari detail produk?',
            a: 'Pastikan Anda menekan tombol “Tambah ke Keranjang” setelah memilih varian (ukuran/warna/komponen). '
                'Jika tetap tidak sesuai, hapus item tersebut dari keranjang lalu tambahkan ulang.',
          ),
          _FaqItem(
            q: 'Kenapa Harga Pricelist/Diskon berbeda dengan manual?',
            a: 'Sistem otomatis membaca katalog pusat. Pastikan pilihan barang '
                '(Tunggal vs Full Set) sudah benar karena harga komponen dalam Set dihitung proporsional.',
          ),
          _FaqItem(
            q: 'Kenapa total pesanan berubah setelah saya ubah qty?',
            a: 'Total dihitung otomatis berdasarkan qty, komponen set (divan/headboard/sorong), dan diskon bertingkat. '
                'Pastikan qty sudah benar sebelum submit.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Approval & Notifikasi',
        items: [
          _FaqItem(
            q: 'Pesanan disubmit, tapi atasan belum dapat notifikasi?',
            a: 'Pastikan internet stabil. Atasan bisa membuka menu Inbox Approval lalu '
                'tarik layar ke bawah (Swipe to Refresh) untuk menarik data terbaru.',
          ),
          _FaqItem(
            q: 'Inbox Approval kosong padahal ada pengajuan?',
            a: 'Coba Swipe to Refresh. Pastikan akun yang digunakan memang memiliki hak Approver/Atasan. '
                'Jika masih kosong, kemungkinan pengajuan belum masuk ke server atau role belum aktif.',
          ),
          _FaqItem(
            q: 'Notifikasi tidak masuk sama sekali, bagaimana memperbaiki?',
            a: 'Cek izin notifikasi aplikasi di pengaturan HP. Pastikan mode Hemat Baterai tidak membatasi aplikasi. '
                'Jika perlu, buka aplikasi sekali agar token notifikasi diperbarui.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Upload Bukti & File',
        items: [
          _FaqItem(
            q: 'Gagal upload foto bukti transfer?',
            a: 'Pastikan Anda telah memberikan Izin (Permission) akses Kamera/Galeri '
                'di pengaturan HP, dan ukuran foto tidak terlalu besar.',
          ),
          _FaqItem(
            q: 'Foto berhasil dipilih tapi tidak terkirim, apa penyebabnya?',
            a: 'Biasanya karena koneksi tidak stabil atau ukuran file besar. '
                'Coba gunakan foto lain yang lebih kecil, pastikan sinyal stabil, lalu upload ulang.',
          ),
        ],
      ),
      _FaqSection(
        title: 'PDF / Dokumen Pesanan',
        items: [
          _FaqItem(
            q: 'Kenapa PDF/Invoice tidak bisa dibuka atau kosong?',
            a: 'Coba ulangi generate/unduh dokumen saat koneksi stabil. '
                'Jika masih bermasalah, tutup aplikasi lalu buka kembali dan coba lagi.',
          ),
          _FaqItem(
            q: 'Tulisan di PDF terlihat aneh/simbol kotak, kenapa?',
            a: 'Biasanya karena font/perangkat tidak mendukung karakter tertentu. '
                'Update aplikasi ke versi terbaru karena perbaikan font biasanya ikut rilis.',
          ),
        ],
      ),
      _FaqSection(
        title: 'Update Aplikasi',
        items: [
          _FaqItem(
            q: 'Aplikasi meminta update dan tidak bisa dilanjutkan, kenapa?',
            a: 'Itu adalah Force Update untuk memastikan perhitungan dan fitur penting selalu versi terbaru. '
                'Silakan update melalui Play Store/App Store, lalu coba lagi.',
          ),
          _FaqItem(
            q: 'Sudah update tapi masih terlihat versi lama?',
            a: 'Pastikan update yang terpasang benar (cek nomor versi). '
                'Jika perlu, tutup aplikasi sepenuhnya lalu buka kembali.',
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        itemCount: sections.length,
        itemBuilder: (context, sectionIndex) {
          final section = sections[sectionIndex];
          return Padding(
            padding: EdgeInsets.only(
                bottom: sectionIndex == sections.length - 1 ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: section.title),
                const SizedBox(height: 10),
                ...List.generate(section.items.length, (i) {
                  final item = section.items[i];
                  final id = '$sectionIndex-$i';
                  final isExpanded = _expandedId == id;
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i == section.items.length - 1 ? 0 : 12),
                    child: _FaqTile(
                      key: ValueKey('faq-$id'),
                      question: item.q,
                      answer: item.a,
                      isExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedId = expanded ? id : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqSection {
  final String title;
  final List<_FaqItem> items;

  const _FaqSection({
    required this.title,
    required this.items,
  });
}

class _FaqItem {
  final String q;
  final String a;

  const _FaqItem({
    required this.q,
    required this.a,
  });
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onExpansionChanged,
    super.key,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;
  late final Animation<double> _fade;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );

    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _size = curve;
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0, 0.85, curve: Curves.easeIn),
    );
    _turns = Tween<double>(begin: 0, end: 0.5).animate(curve);

    if (widget.isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _FaqTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onExpansionChanged(!widget.isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.question,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RotationTransition(
                        turns: _turns,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: widget.isExpanded ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _size,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            widget.answer,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
