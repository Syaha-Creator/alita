import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable search input with built-in clear action.
///
/// Function:
/// - Menyatukan perilaku field pencarian (ikon search, clear button, onChanged).
/// - Mengurangi duplikasi dekorasi `TextField` pada berbagai halaman.
/// - Tetap fleksibel lewat parameter style/decor agar cocok untuk tiap fitur.
class AppSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry contentPadding;
  final InputBorder border;
  final bool filled;
  final Color? fillColor;
  final bool showClearButton;
  final IconData prefixIcon;
  final Color prefixIconColor;
  final Color clearIconColor;
  final double prefixIconSize;
  final double clearIconSize;
  final TextCapitalization textCapitalization;
  final TextAlignVertical textAlignVertical;
  final StrutStyle? strutStyle;
  final bool isDense;
  final bool autofocus;
  final BoxConstraints? prefixIconConstraints;
  final BoxConstraints? suffixIconConstraints;

  /// When false, disables autocorrect (e.g. store/code search — match raw strings).
  final bool autocorrect;

  /// When false, disables keyboard suggestions.
  final bool enableSuggestions;

  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onClear,
    this.textStyle,
    this.hintStyle,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 16,
    ),
    this.border = InputBorder.none,
    this.filled = false,
    this.fillColor,
    this.showClearButton = true,
    this.prefixIcon = Icons.search,
    this.prefixIconColor = AppColors.textSecondary,
    this.clearIconColor = AppColors.textSecondary,
    this.prefixIconSize = 24,
    this.clearIconSize = 20,
    this.textCapitalization = TextCapitalization.none,
    this.textAlignVertical = TextAlignVertical.center,
    this.strutStyle,
    this.isDense = false,
    this.autofocus = false,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late bool _ownsController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _initController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _initController(widget.controller);
    }
  }

  void _initController(TextEditingController? externalController) {
    _ownsController = externalController == null;
    _controller = externalController ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChange);
  }

  void _detachController(TextEditingController? oldController) {
    final target = oldController ?? (_ownsController ? _controller : null);
    target?.removeListener(_handleControllerChange);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  void _handleControllerChange() {
    if (!mounted) return;
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _detachController(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pencarian',
      child: TextField(
      autofocus: widget.autofocus,
      controller: _controller,
      onChanged: widget.onChanged,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      textCapitalization: widget.textCapitalization,
      textAlignVertical: widget.textAlignVertical,
      strutStyle: widget.strutStyle,
      style: widget.textStyle,
      decoration: InputDecoration(
        isDense: widget.isDense,
        hintText: widget.hintText,
        hintStyle: widget.hintStyle,
        prefixIcon: Icon(
          widget.prefixIcon,
          color: widget.prefixIconColor,
          size: widget.prefixIconSize,
        ),
        prefixIconConstraints:
            widget.prefixIconConstraints ??
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: widget.showClearButton && _hasText
            ? IconButton(
                tooltip: 'Hapus teks',
                icon: Icon(
                  Icons.clear,
                  color: widget.clearIconColor,
                  size: widget.clearIconSize,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged?.call('');
                  widget.onClear?.call();
                },
              )
            : null,
        suffixIconConstraints:
            widget.suffixIconConstraints ??
            const BoxConstraints(minWidth: 44, minHeight: 44),
        border: widget.border,
        enabledBorder: widget.border,
        focusedBorder: widget.border,
        contentPadding: widget.contentPadding,
        filled: widget.filled,
        fillColor: widget.fillColor,
      ),
      ),
    );
  }
}
