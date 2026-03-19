/// Centralised configuration for PDF invoice generation.
///
/// Business data (terms, bank info, brand abbreviations, approval-level
/// labels, asset paths) lives here so the section builders stay pure layout.
abstract final class PdfConfig {
  // ── Bank & Company ──

  static const String companyName = 'PT MASSINDO KARYA PRIMA';
  static const String bankName = 'BANK BCA';
  static const String bankAccount = '066-328-8871';

  // ── Purchase Terms & Conditions ──

  static const List<String> purchaseTerms = [
    'Pembayaran dianggap SAH hanya apabila sudah diterima di rekening perusahaan atas nama:\n'
        '$companyName\n'
        '$bankName $bankAccount\n'
        'Pembayaran ke rekening lain tidak akan diakui sebagai pembayaran yang sah.',
    'Barang yang sudah dipesan / dibeli, tidak dapat ditukar atau dikembalikan.',
    'Uang muka yang telah dibayarkan tidak dapat dikembalikan.',
    'Sleep Center berhak mengubah tanggal pengiriman dengan sebelumnya '
        'memberitahukan kepada konsumen.',
    'Surat Pesanan yang sudah lewat 3 (Tiga) bulan namun belum dikirim harus '
        'dilunasi jika tidak akan dianggap batal dan uang muka tidak dapat '
        'dikembalikan',
    'Apabila konsumen menunda pengiriman selama lebih dari 2 (Dua) Bulan dari '
        'tanggal kirim awal, SP dianggap batal dan uang muka tidak dapat '
        'dikembalikan',
    'Pembeli akan dikenakan biaya tambahan untuk pengiriman, pembongkaran, '
        'pengambilan furnitur dll yang disebabkan adanya kesulitan/'
        'ketidakcocokan penempatan furnitur di tempat atau ruangan yang '
        'dikehendaki oleh pembeli.',
    'Jika pengiriman dilakukan lebih dari 1 (Satu) kali, konsumen wajib '
        'melunasi pembelian sebelum pengiriman pertama.',
    'Untuk tipe dan ukuran khusus, pelunasan harus dilakukan saat pemesanan '
        'dan tidak dapat dibatalkan/diganti.',
  ];

  // ── Brand Abbreviations ──

  static const Map<String, String> brandAbbreviations = {
    'spring air': 'SA',
    'therapedic': 'TH',
    'comforta': 'CF',
    'sleep spa': 'SS',
    'superfit': 'SF',
    'isleep': 'isleep',
  };

  /// Resolve a brand name to its 2-letter abbreviation.
  static String brandAbbr(String brand) {
    final lower = brand.toLowerCase();
    for (final entry in brandAbbreviations.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return brand.length >= 2
        ? brand.substring(0, 2).toUpperCase()
        : brand.toUpperCase();
  }

  // ── Approval Level Labels ──

  static const Map<String, String> approvalLevelLabels = {
    'user': 'SC',
    'direct leader': 'Supervisor',
    'indirect leader': 'RSM',
    'controller': 'Controller',
    'analyst': 'Analyst',
  };

  /// Map raw API level string to a display label.
  static String approvalLevelLabel(String level) =>
      approvalLevelLabels[level.toLowerCase()] ?? level;

  // ── Asset Paths ──

  static const String sleepCenterLogo = 'assets/logo/sleepcenter_logo.png';
  static const String approveStampImage = 'assets/images/approve.png';
  static const String paidWatermark = 'assets/images/paid.png';
  static const String approvalWatermark = 'assets/images/approval.png';

  /// Non-Sleep-Center brand logos shown in the PDF header.
  static const List<String> brandLogos = [
    'assets/logo/sleepspa_logo.png',
    'assets/logo/springair_logo.png',
    'assets/logo/therapedic_logo.png',
    'assets/logo/comforta_logo.png',
    'assets/logo/superfit_logo.png',
    'assets/logo/isleep_logo.png',
  ];

  /// Channel code that hides the Sleep Center logo.
  static const String nonSleepCenterChannel = 'S0';

  // ── PDF Font Paths ──

  static const String fontBase = 'assets/fonts/Inter-VariableFont_opsz,wght.ttf';
  static const String fontBold = 'assets/fonts/Inter-Bold.ttf';
  static const String fontBoldFallback = 'assets/fonts/Inter_18pt-Bold.ttf';
  static const String fontItalic =
      'assets/fonts/Inter-Italic-VariableFont_opsz,wght.ttf';

  // ── Payment Ordinals ──

  static const Map<int, String> paymentOrdinals = {
    1: 'Pembayaran Pertama',
    2: 'Pembayaran Kedua',
    3: 'Pembayaran Ketiga',
  };

  static String paymentOrdinalLabel(int index) =>
      paymentOrdinals[index] ?? 'Pembayaran Ke-$index';
}
