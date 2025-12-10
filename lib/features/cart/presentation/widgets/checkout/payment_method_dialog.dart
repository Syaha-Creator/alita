import 'dart:io';
import '../../../../../config/app_constant.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../../../../../core/utils/format_helper.dart';
import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../core/widgets/custom_toast.dart';
import '../../../../../theme/app_colors.dart';
import 'payment_method_model.dart';
import 'payment_helpers.dart';
import 'currency_input_formatter.dart';

/// Dialog untuk menambahkan metode pembayaran baru
class PaymentMethodDialog extends StatefulWidget {
  final double grandTotal;
  final bool isDark;
  final Function(PaymentMethod) onPaymentAdded;
  final List<PaymentMethod> existingPayments;

  const PaymentMethodDialog({
    super.key,
    required this.grandTotal,
    required this.isDark,
    required this.onPaymentAdded,
    required this.existingPayments,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedPaymentCategory = 'transfer';
  String _selectedMethodType = 'bri';
  String? _receiptImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _getRemainingAmount() {
    final totalPaid = widget.existingPayments
        .fold(0.0, (sum, payment) => sum + payment.amount);
    final roundedTotalPaid = double.parse(totalPaid.toStringAsFixed(2));
    final roundedGrandTotal =
        double.parse(widget.grandTotal.toStringAsFixed(2));
    final remaining = roundedGrandTotal - roundedTotalPaid;
    return remaining;
  }

  String _getAmountHintText() {
    final remaining = _getRemainingAmount();
    return FormatHelper.formatCurrency(remaining);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final safePadding = ResponsiveHelper.getSafeAreaPadding(context);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            margin: EdgeInsets.only(
              top: safePadding.top + 60,
              bottom: 0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  _buildDragHandle(colorScheme),
                  _buildHeader(colorScheme),
                  Expanded(child: _buildContent(colorScheme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: ResponsiveHelper.getResponsivePaddingWithZoom(
        context,
        mobile: const EdgeInsets.all(20),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.all(28),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment_outlined,
              color: colorScheme.onPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 20,
                tablet: 22,
                desktop: 24,
              ),
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Pembayaran',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppPadding.p4),
                Text(
                  'Pilih metode dan jumlah pembayaran',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: ResponsiveHelper.getResponsivePaddingWithZoom(
          context,
          mobile: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        tablet: const EdgeInsets.fromLTRB(24, 24, 24, 50),
        desktop: const EdgeInsets.fromLTRB(28, 28, 28, 60),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentCategoryDropdown(colorScheme),
            const SizedBox(height: AppPadding.p16),
            _buildPaymentChannelDropdown(colorScheme),
            const SizedBox(height: AppPadding.p12),
            _buildAmountInput(colorScheme),
            const SizedBox(height: AppPadding.p16),
            _buildReceiptUpload(colorScheme),
            const SizedBox(height: AppPadding.p16),
            _buildReferenceInput(colorScheme),
            const SizedBox(height: AppPadding.p8),
            _buildNoteInput(colorScheme),
            const SizedBox(height: AppPadding.p16),
            _buildActionButtons(colorScheme),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPaymentCategoryDropdown(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppPadding.p12),
        DropdownButtonFormField<String>(
          initialValue: _selectedPaymentCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          items: const [
            DropdownMenuItem(value: 'transfer', child: Text('Transfer Bank')),
            DropdownMenuItem(value: 'credit', child: Text('Kartu Kredit')),
            DropdownMenuItem(value: 'paylater', child: Text('PayLater')),
            DropdownMenuItem(value: 'other', child: Text('Lainnya')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPaymentCategory = value;
                final methods =
                    PaymentHelpers.getPaymentMethodsByCategory(value);
                _selectedMethodType =
                    methods.isNotEmpty ? methods.first['value']! : '';
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaymentChannelDropdown(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Channel Pembayaran',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppPadding.p12),
        DropdownButtonFormField<String>(
          initialValue: _selectedMethodType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: colorScheme.surface,
          ),
          items: PaymentHelpers.getPaymentMethodsByCategory(
                  _selectedPaymentCategory)
              .map((method) => DropdownMenuItem(
                    value: method['value'],
                    child: Text(method['label']!),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedMethodType = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAmountInput(ColorScheme colorScheme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [CurrencyInputFormatter()],
      decoration: InputDecoration(
        labelText: 'Jumlah Pembayaran',
        hintText: _getAmountHintText(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Jumlah pembayaran wajib diisi';
        }
        final amount = FormatHelper.parseCurrencyToDouble(value);
        if (amount <= 0) {
          return 'Jumlah pembayaran tidak valid';
        }
        final remaining = _getRemainingAmount();

        // If remaining is 0 or negative, no more payments allowed
        if (remaining <= 0) {
          return 'Pembayaran sudah lunas, tidak bisa menambah pembayaran baru';
        }

        // Use higher epsilon for currency comparison (1 rupiah tolerance)
        const double epsilon = 1.0;
        final roundedAmount = (amount * 100).round() / 100;
        final roundedRemaining = (remaining * 100).round() / 100;

        // Check if amount exceeds remaining (with tolerance)
        if (roundedAmount > roundedRemaining + epsilon) {
          return 'Jumlah tidak boleh melebihi sisa pembayaran (${FormatHelper.formatCurrency(remaining)})';
        }
        return null;
      },
    );
  }

  Widget _buildReceiptUpload(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Struk Pembayaran *',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppPadding.p12),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline,
                style: BorderStyle.solid,
              ),
            ),
            child: _receiptImagePath != null
                ? _buildReceiptPreview(colorScheme)
                : _buildImagePlaceholder(colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptPreview(ColorScheme colorScheme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_receiptImagePath!),
            width: double.infinity,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder(colorScheme);
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _removeReceiptImage,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppPadding.p8),
          Text(
            'Tap untuk ambil foto atau pilih dari galeri',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppPadding.p4),
          Text(
            'Struk pembayaran wajib diisi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.error, // Status color
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceInput(ColorScheme colorScheme) {
    return TextFormField(
      controller: _referenceController,
      decoration: InputDecoration(
        labelText: 'Referensi/No. Transaksi (Opsional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildNoteInput(ColorScheme colorScheme) {
    return TextFormField(
      controller: _noteController,
      decoration: InputDecoration(
        labelText: 'Catatan Pembayaran (Opsional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      maxLines: 3,
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppPadding.p12),
        Expanded(
          child: ElevatedButton(
            onPressed: _addPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Tambah',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_receiptImagePath == null || _receiptImagePath!.isEmpty) {
        CustomToast.showToast(
          'Foto struk pembayaran wajib diisi',
          ToastType.error,
        );
        return;
      }

      final amount = FormatHelper.parseCurrencyToDouble(_amountController.text);
      final reference = _referenceController.text.trim();
      final note = _noteController.text.trim();

      final today = DateTime.now();
      final paymentDate =
          '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';

      final payment = PaymentMethod(
        methodType: _selectedMethodType,
        methodName: PaymentHelpers.getPaymentName(_selectedMethodType),
        amount: amount,
        reference: reference.isEmpty ? null : reference,
        receiptImagePath: _receiptImagePath!,
        paymentDate: paymentDate,
        note: note.isEmpty ? null : note,
      );

      widget.onPaymentAdded(payment);
      Navigator.pop(context);
    }
  }

  void _showImageSourceDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            _buildImageSourceOption(
              icon: Icons.camera_alt,
              iconColor: AppColors.success,
              title: 'Ambil Foto',
              subtitle: 'Gunakan kamera untuk mengambil foto struk',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.camera);
              },
            ),
            _buildImageSourceOption(
              icon: Icons.photo_library,
              iconColor: colorScheme.primary,
              title: 'Pilih dari Galeri',
              subtitle: 'Pilih foto struk dari galeri',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.gallery);
              },
            ),
            _buildImageSourceOption(
              icon: Icons.folder_open,
              iconColor: Colors.orange,
              title: 'Pilih File',
              subtitle: 'Pilih file gambar dari penyimpanan',
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImageFromFile();
              },
            ),
            const SizedBox(height: AppPadding.p20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _saveImageFile(image.path);
      }
    } catch (e) {
      CustomToast.showToast(
          'Gagal mengambil foto: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _pickReceiptImageFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          await _saveImageFile(filePath);
        }
      }
    } catch (e) {
      CustomToast.showToast(
          'Gagal memilih file: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _saveImageFile(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      await _compressImage(sourcePath, filePath);

      setState(() {
        _receiptImagePath = filePath;
      });

      CustomToast.showToast('Foto struk berhasil diupload', ToastType.success);
    } catch (e) {
      CustomToast.showToast(
          'Gagal menyimpan gambar: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _compressImage(String sourcePath, String targetPath) async {
    try {
      final File sourceFile = File(sourcePath);
      final Uint8List imageBytes = await sourceFile.readAsBytes();

      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      const int targetSizeBytes = 150 * 1024;

      int quality = 95;
      Uint8List compressedBytes = Uint8List(0);

      while (quality > 10) {
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(originalImage, quality: quality));

        if (compressedBytes.length <= targetSizeBytes) {
          break;
        }

        quality -= 10;
      }

      if (compressedBytes.length > targetSizeBytes) {
        double resizeFactor =
            math.sqrt(targetSizeBytes / compressedBytes.length);

        int newWidth = (originalImage.width * resizeFactor).round();
        int newHeight = (originalImage.height * resizeFactor).round();

        newWidth = math.max(newWidth, 200);
        newHeight = math.max(newHeight, 200);

        final img.Image resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
        );

        compressedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
      }

      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressedBytes);
    } catch (e) {
      final File sourceFile = File(sourcePath);
      await sourceFile.copy(targetPath);
    }
  }

  void _removeReceiptImage() {
    setState(() {
      _receiptImagePath = null;
    });
  }
}
