import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';

/// Version footer at bottom of profile page.
class ProfileVersionFooter extends StatelessWidget {
  const ProfileVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}
