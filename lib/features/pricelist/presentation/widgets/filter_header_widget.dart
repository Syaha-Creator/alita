import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/area_utils.dart';
import '../../../../core/widgets/filter_pill.dart';
import '../../../../core/widgets/selection_bottom_sheet.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../logic/product_provider.dart';

/// Format area name for display (Title Case, no uppercase).
String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      })
      .join(' ');
}

void _showSelectionBottomSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String? selectedItem,
  required String Function(String item) labelBuilder,
  required ValueChanged<String> onItemSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SelectionBottomSheet<String>(
      title: title,
      items: items,
      selectedItem: selectedItem,
      labelBuilder: labelBuilder,
      onItemSelected: onItemSelected,
    ),
  );
}

/// Cascading filter header: Area → Channel → Brand (horizontal quick dropdown pills)
class FilterHeaderWidget extends ConsumerWidget {
  const FilterHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync: when areas load and selected is not in list, re-resolve default (fix Sumsel→Palembang etc)
    ref.listen<List<String>>(areasProvider, (prev, next) {
      if (next.isEmpty) return;
      final selected = ref.read(selectedAreaProvider);
      final inList = next.any((a) => a.toLowerCase() == selected.toLowerCase());
      if (!inList) {
        final auth = ref.read(authProvider);
        final userArea = auth.defaultArea.isNotEmpty ? auth.defaultArea : '';
        final resolved = AreaUtils.resolveDefaultArea(userArea, next);
        ref.read(selectedAreaProvider.notifier).state = resolved;
      }
    });

    final area = ref.watch(selectedAreaProvider);
    final selectedChannel = ref.watch(selectedChannelProvider);
    final selectedBrand = ref.watch(selectedBrandProvider);

    final areas = ref.read(areasProvider);
    final channels = ref.read(channelsProvider);
    final brands = ref.read(brandsProvider);
    final areaNotifier = ref.read(selectedAreaProvider.notifier);
    final channelNotifier = ref.read(selectedChannelProvider.notifier);
    final brandNotifier = ref.read(selectedBrandProvider.notifier);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterPill(
              icon: Icons.location_on,
              text: _toTitleCase(area),
              isActive: true,
              onTap: () => _showSelectionBottomSheet(
                context: context,
                title: 'Pilih Area',
                items: areas,
                selectedItem: area,
                labelBuilder: _toTitleCase,
                onItemSelected: (value) {
                  areaNotifier.state = value;
                },
              ),
            ),
            const SizedBox(width: 8),
            FilterPill(
              icon: Icons.storefront,
              text: selectedChannel ?? 'Channel',
              isActive: selectedChannel != null,
              onTap: () => _showSelectionBottomSheet(
                context: context,
                title: 'Pilih Channel',
                items: channels,
                selectedItem: selectedChannel,
                labelBuilder: (value) => value,
                onItemSelected: (value) {
                  channelNotifier.state = value;
                  brandNotifier.state = null;
                },
              ),
            ),
            const SizedBox(width: 8),
            FilterPill(
              icon: Icons.sell_outlined,
              text: selectedBrand ?? 'Brand',
              isActive: selectedBrand != null,
              onTap: () {
                if (selectedChannel == null) {
                  AppFeedback.plain(
                    context,
                    'Pilih Channel dulu',
                    floating: true,
                  );
                  return;
                }
                _showSelectionBottomSheet(
                  context: context,
                  title: 'Pilih Brand',
                  items: brands,
                  selectedItem: selectedBrand,
                  labelBuilder: (value) => value,
                  onItemSelected: (value) {
                    brandNotifier.state = value;
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
