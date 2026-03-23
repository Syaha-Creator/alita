import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/telemetry_access.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/enums/order_status.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../history/logic/order_history_provider.dart';
import '../../logic/profile_provider.dart';
import '../../../approval/logic/approval_inbox_provider.dart';

/// Profile / Settings Page — clean minimalist design
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(approvalInboxProvider.notifier).fetchInbox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final canOpenTelemetry = TelemetryAccess.canAccess(auth);
    final profile = ref.watch(profileProvider).valueOrNull;
    final workTitle = profile?.workTitle.toLowerCase() ?? '';
    final isApprover = workTitle.contains('manager') ||
        workTitle.contains('supervisor') ||
        workTitle.contains('spv') ||
        workTitle.contains('rsm') ||
        workTitle.contains('analyst') ||
        workTitle.contains('head') ||
        workTitle.contains('director');

    final orderHistoryAsync = ref.watch(orderHistoryProvider);
    final inboxState = ref.watch(approvalInboxProvider);

    final now = DateTime.now();

    // "Pesanan Bulan Ini" — selalu personal, filter ke bulan & tahun berjalan
    final totalPesanan = orderHistoryAsync.when(
      data: (orders) {
        final count = orders.where((o) {
          final date = DateTime.tryParse(o.orderDate) ?? DateTime(2000);
          return date.month == now.month && date.year == now.year;
        }).length;
        return count.toString();
      },
      loading: () => '...',
      error: (_, __) => '0',
    );

    // "Menunggu Approval" — 2 mode:
    // Atasan → antrean diskon bawahan yang belum disetujui
    // Sales  → pesanan pribadi yang masih berstatus Pending
    final totalPending = isApprover
        ? (inboxState.isLoading
            ? '...'
            : inboxState.pendingApprovals.length.toString())
        : orderHistoryAsync.when(
            data: (orders) => orders
                .where((o) =>
                    OrderStatusX.fromRaw(o.status) == OrderStatus.pending)
                .length
                .toString(),
            loading: () => '...',
            error: (_, __) => '0',
          );

    final pendingLabel =
        isApprover ? 'Antrean Persetujuan' : 'Menunggu Approval';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        elevation: 0,
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator.adaptive(
        color: AppColors.accent,
        onRefresh: () async {
          final isOffline = ref.read(isOfflineProvider);
          if (isOffline) {
            if (context.mounted) {
              AppFeedback.show(context,
                  message: 'Sedang offline — tidak bisa memuat ulang.',
                  type: AppFeedbackType.warning);
            }
            return;
          }
          ref.invalidate(profileProvider);
          unawaited(ref.read(approvalInboxProvider.notifier).fetchInbox());
          try {
            await ref.read(profileProvider.future);
          } catch (_) {
            if (context.mounted) {
              AppFeedback.show(context,
                  message: 'Gagal memuat ulang profil.',
                  type: AppFeedbackType.warning);
            }
          }
        },
        child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Header Profil (dinamis dari API contact_work_experiences) ──
          _buildProfileHeaderFromApi(context),
          const SizedBox(height: 24),

          // ── Mini Dashboard Performa ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentLight, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accentBorder, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalPesanan,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Pesanan Bulan Ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.accentBorder),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        totalPending,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pendingLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Menu Section: Aktivitas ──
          _buildSectionLabel(context, 'Aktivitas'),
          const SizedBox(height: 8),
          _buildMenuCard(context, [
            _MenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Pesanan',
              onTap: () => context.push('/order_history'),
            ),
            _MenuItem(
              icon: Icons.description_outlined,
              title: 'Riwayat Penawaran',
              onTap: () => context.push('/quotation_history'),
            ),
            if (isApprover)
              _MenuItem(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Persetujuan Diskon',
                onTap: () => context.push('/approval_inbox'),
              ),
          ]),
          const SizedBox(height: 20),

          // ── Menu Section: Lainnya ──
          _buildSectionLabel(context, 'Lainnya'),
          const SizedBox(height: 8),
          _buildMenuCard(context, [
            _MenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan',
              onTap: () => context.push('/help_center'),
            ),
            if (canOpenTelemetry)
              _MenuItem(
                icon: Icons.bug_report_outlined,
                title: 'Telemetry Debug (Admin)',
                onTap: () => context.push('/telemetry_debug'),
              ),
            _MenuItem(
              icon: Icons.info_outline_rounded,
              title: 'Tentang Aplikasi',
              onTap: () => _showAbout(context),
            ),
          ]),
          const SizedBox(height: 32),

          // ── Logout Button ──
          _buildLogoutButton(context),
          const SizedBox(height: 16),

          // ── Version ──
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version;
                final label = version != null
                    ? 'Alita Pricelist v$version'
                    : 'Alita Pricelist';
                return Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  // ───────────────────── Header ─────────────────────

  Widget _buildProfileHeaderFromApi(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final auth = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: profileAsync.when(
        loading: () => _buildProfileHeaderContent(
          name: auth.userName.isNotEmpty ? auth.userName : auth.userEmail,
          email: auth.userEmail,
          imageUrl: auth.userImageUrl,
          areaName: auth.defaultArea,
        ),
        error: (_, __) => _buildProfileHeaderContent(
          name: auth.userName.isNotEmpty ? auth.userName : auth.userEmail,
          email: auth.userEmail,
          imageUrl: auth.userImageUrl,
          areaName: auth.defaultArea,
        ),
        data: (profile) {
          final name = profile?.name ??
              (auth.userName.isNotEmpty ? auth.userName : auth.userEmail);
          final email = profile?.email ?? auth.userEmail;
          final areaName = profile?.areaName ?? auth.defaultArea;
          return _buildProfileHeaderContent(
            name: name,
            email: email,
            imageUrl: auth.userImageUrl,
            areaName: areaName,
            workTitle: profile?.workTitle ?? '',
          );
        },
      ),
    );
  }

  Widget _buildProfileHeaderContent({
    required String name,
    required String email,
    required String imageUrl,
    required String areaName,
    String workTitle = '',
  }) {
    final formattedArea = areaName.isEmpty
        ? ''
        : '${areaName[0].toUpperCase()}${areaName.substring(1).toLowerCase()}';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  memCacheWidth: 160,
                  memCacheHeight: 160,
                  imageBuilder: (_, provider) => CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    backgroundImage: provider,
                  ),
                  placeholder: (_, __) => CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: _initialsText(name),
                  ),
                  errorWidget: (_, __, ___) => CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: _initialsText(name),
                  ),
                )
              : CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: _initialsText(name),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        if (workTitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            workTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 12),
        if (formattedArea.isNotEmpty)
          _infoPill(
            icon: Icons.location_on,
            label: 'Area: $formattedArea',
          ),
      ],
    );
  }

  static Widget _initialsText(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.surface,
      ),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Menu ─────────────────────

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 72, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  // ───────────────────── Logout ─────────────────────

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    hapticTap();
    showAdaptiveAlert(
      context: context,
      title: 'Keluar',
      content: 'Apakah Anda yakin ingin keluar dari akun?',
      actions: [
        const AdaptiveAction(
          label: 'Batal',
          color: AppColors.textSecondary,
          popResult: false,
        ),
        AdaptiveAction(
          label: 'Keluar',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }

  // ───────────────────── Dialogs ─────────────────────

  Future<void> _showAbout(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionLabel = 'Alita Pricelist v${packageInfo.version}';

    if (!context.mounted) return;
    if (isIOS) {
      unawaited(showCupertinoDialog<void>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Tentang Aplikasi'),
          content: _AboutDialogContent(versionLabel: versionLabel),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ));
      return;
    }

    unawaited(showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: _AboutDialogContent(versionLabel: versionLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    ));
  }
}

/// Reusable body for About app dialog (iOS & Android).
class _AboutDialogContent extends StatelessWidget {
  const _AboutDialogContent({required this.versionLabel});

  static const String _description =
      'Aplikasi resmi manajemen katalog produk, kalkulasi harga, '
      'dan pembuatan pesanan untuk jaringan penjualan Massindo Group.';
  static const String _copyright =
      '© 2026 Massindo Group. All rights reserved.';

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          versionLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          _description,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        const Text(
          _copyright,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Internal data class for menu items
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
