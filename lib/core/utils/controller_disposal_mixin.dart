// File: lib/core/mixins/controller_disposal_mixin.dart
import 'package:flutter/material.dart';

/// Mixin untuk mengelola disposal TextEditingController dan FocusNode secara otomatis pada StatefulWidget.
mixin ControllerDisposalMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  /// Register TextEditingController untuk auto-disposal
  TextEditingController registerController([String? initialText]) {
    final controller = TextEditingController(text: initialText);
    _controllers.add(controller);
    return controller;
  }

  /// Register FocusNode untuk auto-disposal
  FocusNode registerFocusNode() {
    final focusNode = FocusNode();
    _focusNodes.add(focusNode);
    return focusNode;
  }

  @override
  void dispose() {
    // Dispose all registered controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    _controllers.clear();

    // Dispose all registered focus nodes
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _focusNodes.clear();

    super.dispose();
  }
}
