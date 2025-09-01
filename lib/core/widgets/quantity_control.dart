import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_constant.dart';

/// Widget kontrol jumlah (quantity) dengan tombol tambah/kurang.
class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onDelete;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIconButton(
          context,
          quantity > 1 ? Icons.remove : Icons.delete_outline,
          quantity > 1 ? Colors.redAccent : Colors.red,
          quantity > 1 ? onDecrement : (onDelete ?? onDecrement),
          tooltip: quantity > 1 ? 'Kurangi jumlah' : 'Hapus item',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppPadding.p8),
          child: Text(
            quantity.toString(),
            style: GoogleFonts.montserrat(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        _buildIconButton(
          context,
          Icons.add,
          Colors.green,
          onIncrement,
          tooltip: 'Tambah jumlah',
        ),
      ],
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, Color color, VoidCallback onTap,
      {String? tooltip}) {
    return Material(
      shape: const CircleBorder(),
      color: color.withOpacity(0.1),
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.p8),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
