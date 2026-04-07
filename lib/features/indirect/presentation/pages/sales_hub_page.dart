import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/sales_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/telemetry_access.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../logic/indirect_session_provider.dart';
import '../../logic/sales_mode_bootstrap.dart';
import '../../logic/sales_mode_provider.dart';

/// Pintu masuk: pilih Direct vs Indirect sebelum katalog (hanya admin).
class SalesHubPage extends ConsumerStatefulWidget {
  const SalesHubPage({super.key});

  @override
  ConsumerState<SalesHubPage> createState() => _SalesHubPageState();
}

class _SalesHubPageState extends ConsumerState<SalesHubPage> {
  bool _redirectChecked = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (!_redirectChecked &&
        auth.isLoggedIn &&
        !TelemetryAccess.canChooseSalesMode(auth.userId)) {
      _redirectChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_redirectNonAdmin(auth));
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alita Pricelist'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppLayoutTokens.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih jenis pricelist',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space8),
              Text(
                'Direct untuk penjualan langsung; Indirect untuk distributor/toko assign '
                'dengan diskon toko dari server.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final row = c.maxWidth > 560;
                    final cards = [
                      _ModeCard(
                        title: 'Direct',
                        subtitle: 'Sleep center / penjualan langsung',
                        icon: Icons.storefront_outlined,
                        color: AppColors.primary,
                        onTap: () async {
                          await ref.read(cartProvider.notifier).clearCart();
                          ref.read(indirectSessionProvider.notifier).clear();
                          await ref
                              .read(salesModeProvider.notifier)
                              .setMode(SalesMode.direct);
                          if (context.mounted) context.go('/');
                        },
                      ),
                      _ModeCard(
                        title: 'Indirect',
                        subtitle: 'Toko assign + diskon toko',
                        icon: Icons.business_outlined,
                        color: AppColors.accent,
                        onTap: () async {
                          await ref.read(cartProvider.notifier).clearCart();
                          ref.read(indirectSessionProvider.notifier).clear();
                          await ref
                              .read(salesModeProvider.notifier)
                              .setMode(SalesMode.indirect);
                          if (context.mounted) context.go('/');
                        },
                      ),
                    ];
                    if (row) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: AppLayoutTokens.space16),
                          Expanded(child: cards[1]),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(height: AppLayoutTokens.space16),
                        Expanded(child: cards[1]),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _redirectNonAdmin(AuthState auth) async {
    await syncSalesModeForNonAdminUser(
      ref,
      userId: auth.userId,
      addressNumber: auth.addressNumber,
    );
    if (!mounted) return;
    context.go('/');
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius16),
        child: Padding(
          padding: const EdgeInsets.all(AppLayoutTokens.space20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: AppLayoutTokens.space12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppLayoutTokens.space8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
