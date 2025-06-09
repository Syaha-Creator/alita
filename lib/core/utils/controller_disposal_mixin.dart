// File: lib/core/mixins/controller_disposal_mixin.dart
import 'package:flutter/material.dart';

/// Mixin untuk mengelola disposal TextEditingController dan FocusNode secara otomatis
/// Gunakan mixin ini pada StatefulWidget untuk mencegah memory leaks
mixin ControllerDisposalMixin<T extends StatefulWidget> on State<T> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<ScrollController> _scrollControllers = [];
  final List<AnimationController> _animationControllers = [];
  final List<PageController> _pageControllers = [];

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

  /// Register ScrollController untuk auto-disposal
  ScrollController registerScrollController() {
    final scrollController = ScrollController();
    _scrollControllers.add(scrollController);
    return scrollController;
  }

  /// Register AnimationController untuk auto-disposal
  AnimationController registerAnimationController({
    required TickerProvider vsync,
    required Duration duration,
    Duration? reverseDuration,
  }) {
    final animationController = AnimationController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
    );
    _animationControllers.add(animationController);
    return animationController;
  }

  /// Register PageController untuk auto-disposal
  PageController registerPageController({
    int initialPage = 0,
    bool keepPage = true,
    double viewportFraction = 1.0,
  }) {
    final pageController = PageController(
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
    );
    _pageControllers.add(pageController);
    return pageController;
  }

  /// Manual disposal untuk controller tertentu
  void disposeController(TextEditingController controller) {
    if (_controllers.contains(controller)) {
      _controllers.remove(controller);
      controller.dispose();
    }
  }

  /// Manual disposal untuk focus node tertentu
  void disposeFocusNode(FocusNode focusNode) {
    if (_focusNodes.contains(focusNode)) {
      _focusNodes.remove(focusNode);
      focusNode.dispose();
    }
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

    // Dispose all registered scroll controllers
    for (final scrollController in _scrollControllers) {
      scrollController.dispose();
    }
    _scrollControllers.clear();

    // Dispose all registered animation controllers
    for (final animationController in _animationControllers) {
      animationController.dispose();
    }
    _animationControllers.clear();

    // Dispose all registered page controllers
    for (final pageController in _pageControllers) {
      pageController.dispose();
    }
    _pageControllers.clear();

    super.dispose();
  }
}
