import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/telemetry_access.dart';
import '../../../../core/enums/order_status.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../history/logic/order_history_provider.dart';
import '../../logic/profile_provider.dart';
import '../../../approval/logic/approval_inbox_provider.dart';
import '../widgets/about_dialog_content.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_menu_card.dart';
import '../widgets/profile_refreshable.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_version_footer.dart';

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
    final canOpenTelemetry = TelemetryAccess.canAccess(auth.userId);
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
      body: ProfileRefreshable(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            const ProfileHeaderCard(),
            const SizedBox(height: 24),
            ProfileStatsCard(
              totalPesanan: totalPesanan,
              totalPending: totalPending,
              pendingLabel: pendingLabel,
            ),
            const SizedBox(height: 24),
            const ProfileSectionLabel(label: 'Aktivitas'),
            const SizedBox(height: 8),
            ProfileMenuCard(
              items: [
                ProfileMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Riwayat Pesanan',
                  onTap: () => context.push('/order_history'),
                ),
                ProfileMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Riwayat Penawaran',
                  onTap: () => context.push('/quotation_history'),
                ),
                if (isApprover)
                  ProfileMenuItem(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Persetujuan Diskon',
                    onTap: () => context.push('/approval_inbox'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const ProfileSectionLabel(label: 'Lainnya'),
            const SizedBox(height: 8),
            ProfileMenuCard(
              items: [
                ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Pusat Bantuan',
                  onTap: () => context.push('/help_center'),
                ),
                if (canOpenTelemetry)
                  ProfileMenuItem(
                    icon: Icons.bug_report_outlined,
                    title: 'Telemetry Debug (Admin)',
                    onTap: () => context.push('/telemetry_debug'),
                  ),
                ProfileMenuItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Tentang Aplikasi',
                  onTap: () => AboutDialogContent.show(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const ProfileLogoutButton(),
            const SizedBox(height: 16),
            const ProfileVersionFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
