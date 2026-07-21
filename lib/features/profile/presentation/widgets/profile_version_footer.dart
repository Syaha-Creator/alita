import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';

/// App version, used only by [ProfileVersionFooter] below.
final _packageInfoProvider =
    FutureProvider.autoDispose<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Version footer at bottom of profile page.
class ProfileVersionFooter extends ConsumerWidget {
  const ProfileVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(_packageInfoProvider);
    final label = packageInfo.maybeWhen(
      data: (info) => 'Alita Pricelist v${info.version}',
      orElse: () => 'Alita Pricelist',
    );

    return Center(
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}
