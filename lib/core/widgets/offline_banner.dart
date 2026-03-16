import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// WhatsApp/Telegram-style banner shown below the status bar when offline.
/// Wraps the entire app content via [MaterialApp.router]'s `builder`.
class OfflineBannerWrapper extends ConsumerWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    return Stack(
      children: [
        // Shift content down when banner is visible
        Positioned.fill(
          top: isOffline ? _kBannerHeight : 0,
          child: child,
        ),
        // Animated banner at the top
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: isOffline ? 0 : -_kBannerHeight,
          left: 0,
          right: 0,
          height: _kBannerHeight,
          child: const _OfflineBanner(),
        ),
      ],
    );
  }
}

const double _kBannerHeight = 32;

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF424242),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _kBannerHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                'Tidak ada koneksi internet',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
