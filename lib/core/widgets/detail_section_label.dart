import 'package:flutter/material.dart';

/// Reusable label text for subsection titles in detail pages.
///
/// Function:
/// - Menstandarkan gaya label subsection agar konsisten.
/// - Mengurangi duplikasi TextStyle pada detail screens.
class DetailSectionLabel extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const DetailSectionLabel({super.key, required this.title, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          style ??
          const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.2,
          ),
    );
  }
}
