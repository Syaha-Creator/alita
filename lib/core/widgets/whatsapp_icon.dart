import 'package:flutter/material.dart';

/// Renders the official WhatsApp brand logo from app assets.
///
/// Use instead of generic `Icons.chat_*` whenever the action is
/// explicitly WhatsApp-related (open chat, share via WA, etc.).
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WhatsApp',
      image: true,
      child: Image.asset(
        'assets/logo/whatsapp-icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'WhatsApp',
      ),
    );
  }
}
