import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';

/// WhatsApp/Telegram-style banner shown below the status bar when offline.
/// Wraps the entire app content via [MaterialApp.router]'s `builder`.
class OfflineBannerWrapper extends ConsumerWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned.fill(
          top: isOffline ? _kBannerSlotHeight : 0,
          child: child,
        ),
        Positioned(
          top: topInset + AppLayoutTokens.space6,
          left: 0,
          right: 0,
          child: ClipRect(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              offset: isOffline ? Offset.zero : const Offset(0, -1.4),
              child: const _OfflineBanner(),
            ),
          ),
        ),
      ],
    );
  }
}

const double _kBannerHeight = 40;
const double _kBannerSlotHeight = 56;

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino = platform == TargetPlatform.iOS;

    return Semantics(
      liveRegion: true,
      label: 'Tidak ada koneksi internet',
      child: SizedBox(
        height: _kBannerSlotHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppLayoutTokens.space12),
          child: isCupertino
              ? const _CupertinoOfflineBanner()
              : const _MaterialOfflineBanner(),
        ),
      ),
    );
  }
}

class _CupertinoOfflineBanner extends StatelessWidget {
  const _CupertinoOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: _kBannerHeight,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
            border: Border.all(
              color: AppColors.onPrimary.withValues(alpha: 0.45),
              width: 0.9,
            ),
            boxShadow: [AppLayoutTokens.cardShadowSoft],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: AppColors.error,
              ),
              SizedBox(width: AppLayoutTokens.space8),
              Text(
                'Tidak ada koneksi internet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialOfflineBanner extends StatelessWidget {
  const _MaterialOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
        border: Border.all(
          color: AppColors.accentLight.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [AppLayoutTokens.cardShadowSoft],
      ),
      child: const SizedBox(
        height: _kBannerHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 16,
              color: AppColors.onPrimaryMedium,
            ),
            SizedBox(width: AppLayoutTokens.space8),
            Text(
              'Tidak ada koneksi internet',
              style: TextStyle(
                color: AppColors.onPrimaryHigh,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
