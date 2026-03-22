import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';

/// Reusable renderer for `AsyncValue` states (loading/error/data).
///
/// Uses [AnimatedSwitcher] for smooth crossfades between states.
/// A monotonic counter prevents duplicate-key crashes when the provider
/// rapidly flip-flops between the same state type (e.g. loading → data → loading).
class AsyncStateView<T> extends StatefulWidget {
  final AsyncValue<T> state;
  final Widget Function(T data) dataBuilder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final bool showDefaultLoading;
  final bool showDefaultError;
  final Duration transitionDuration;

  const AsyncStateView({
    super.key,
    required this.state,
    required this.dataBuilder,
    this.loading,
    this.errorBuilder,
    this.showDefaultLoading = true,
    this.showDefaultError = true,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AsyncStateView<T>> createState() => _AsyncStateViewState<T>();
}

class _AsyncStateViewState<T> extends State<AsyncStateView<T>> {
  String _prevTag = '';
  int _epoch = 0;

  /// Returns a key unique per state-type transition.
  /// Re-entering the same type (loading → data → loading) bumps the epoch
  /// so the old outgoing child and the new incoming child never share a key.
  ValueKey<String> _keyFor(String tag) {
    if (tag != _prevTag) {
      _epoch++;
      _prevTag = tag;
    }
    return ValueKey('${tag}_$_epoch');
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.state.when(
      loading: () {
        final key = _keyFor('loading');
        if (widget.loading case final loadingWidget?) {
          return KeyedSubtree(
            key: key,
            child: Semantics(
              liveRegion: true,
              label: 'Memuat',
              child: loadingWidget,
            ),
          );
        }
        if (!widget.showDefaultLoading) {
          return SizedBox.shrink(key: key);
        }
        return KeyedSubtree(
          key: key,
          child: Semantics(
            liveRegion: true,
            label: 'Memuat',
            child: const Center(
              child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        final key = _keyFor('error');
        if (widget.errorBuilder case final builder?) {
          return KeyedSubtree(key: key, child: builder(error, stackTrace));
        }
        if (!widget.showDefaultError) {
          return SizedBox.shrink(key: key);
        }
        return KeyedSubtree(
          key: key,
          child: Center(
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
          ),
        );
      },
      data: (data) {
        final key = _keyFor('data');
        return KeyedSubtree(key: key, child: widget.dataBuilder(data));
      },
    );

    return AnimatedSwitcher(
      duration: widget.transitionDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
