import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_constant.dart';

class QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const QuantityControl({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIconButton(
          context,
          Icons.remove,
          Colors.redAccent,
          onDecrement,
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
        ),
      ],
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      shape: const CircleBorder(),
      color: color.withOpacity(0.1),
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(AppPadding.p8),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
