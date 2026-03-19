import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

/// Reusable renderer for `AsyncValue` states (loading/error/data).
///
/// Function:
/// - Menyatukan pola `when(loading/error/data)` agar tidak berulang.
/// - Menjaga tampilan loading/error konsisten lintas halaman.
/// - Tetap fleksibel: caller bisa override loading/error/default widgets.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) dataBuilder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final bool showDefaultLoading;
  final bool showDefaultError;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.dataBuilder,
    this.loading,
    this.errorBuilder,
    this.showDefaultLoading = true,
    this.showDefaultError = true,
  });

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () {
        if (loading != null) return loading!;
        if (!showDefaultLoading) return const SizedBox.shrink();
        return const Center(
          child: CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation(AppColors.accent)),
        );
      },
      error: (error, stackTrace) {
        if (errorBuilder != null) {
          return errorBuilder!(error, stackTrace);
        }
        if (!showDefaultError) return const SizedBox.shrink();
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
      data: dataBuilder,
    );
  }
}
