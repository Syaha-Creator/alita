import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../logic/profile_provider.dart';

/// Profile header card with avatar, name, email, area.
///
/// Reads [profileProvider] and [authProvider] for data; shows loading/error
/// fallback from auth when profile is not yet loaded.
class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        loading: () => _ProfileHeaderContent(
          name: auth.userName.isNotEmpty ? auth.userName : auth.userEmail,
          email: auth.userEmail,
          imageUrl: auth.userImageUrl,
          areaName: auth.defaultArea,
        ),
        error: (_, __) => _ProfileHeaderContent(
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
          return _ProfileHeaderContent(
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
}

class _ProfileHeaderContent extends StatelessWidget {
  const _ProfileHeaderContent({
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.areaName,
    this.workTitle = '',
  });

  final String name;
  final String email;
  final String imageUrl;
  final String areaName;
  final String workTitle;

  @override
  Widget build(BuildContext context) {
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
                    child: _InitialsText(name: name),
                  ),
                  errorWidget: (_, __, ___) => CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: _InitialsText(name: name),
                  ),
                )
              : CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: _InitialsText(name: name),
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
          ProfileInfoPill(
            icon: Icons.location_on,
            label: 'Area: $formattedArea',
          ),
      ],
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.surface,
      ),
    );
  }
}

/// Accent pill for profile header (e.g. Area: Jabodetabek).
class ProfileInfoPill extends StatelessWidget {
  const ProfileInfoPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
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
}
