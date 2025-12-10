import 'package:flutter/material.dart';
import '../../config/app_constant.dart';

/// Helper widgets untuk spacing yang konsisten menggunakan AppPadding
class Spacing {
  Spacing._();

  /// Vertical spacing widgets
  static Widget v2() => const SizedBox(height: AppPadding.p2);
  static Widget v4() => const SizedBox(height: AppPadding.p4);
  static Widget v8() => const SizedBox(height: AppPadding.p8);
  static Widget v10() => const SizedBox(height: AppPadding.p10);
  static Widget v12() => const SizedBox(height: AppPadding.p12);
  static Widget v16() => const SizedBox(height: AppPadding.p16);
  static Widget v20() => const SizedBox(height: AppPadding.p20);
  static Widget v24() => const SizedBox(height: AppPadding.p24);

  /// Horizontal spacing widgets
  static Widget h2() => const SizedBox(width: AppPadding.p2);
  static Widget h4() => const SizedBox(width: AppPadding.p4);
  static Widget h8() => const SizedBox(width: AppPadding.p8);
  static Widget h10() => const SizedBox(width: AppPadding.p10);
  static Widget h12() => const SizedBox(width: AppPadding.p12);
  static Widget h16() => const SizedBox(width: AppPadding.p16);
  static Widget h20() => const SizedBox(width: AppPadding.p20);
  static Widget h24() => const SizedBox(width: AppPadding.p24);
}
