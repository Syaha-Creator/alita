import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../logic/product_provider.dart';

/// Pinterest-style floating search bar
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28), // Pill shape
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppSearchField(
        controller: _controller,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        hintText: 'Search products...',
        textStyle: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.0),
        hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textTertiary,
              height: 1.0,
            ),
        strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.0),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 56),
      ),
    );
  }
}
