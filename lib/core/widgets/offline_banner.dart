import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';

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
        Positioned.fill(
          top: isOffline ? _kBannerHeight : 0,
          child: child,
        ),
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
    return const Material(
      color: AppColors.textPrimary,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _kBannerHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 14,
                color: AppColors.onPrimaryMedium,
              ),
              SizedBox(width: 8),
              Text(
                'Tidak ada koneksi internet',
                style: TextStyle(
                  color: AppColors.onPrimaryHigh,
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
