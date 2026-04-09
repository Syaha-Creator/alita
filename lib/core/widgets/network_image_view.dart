import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/product_image_utils.dart';

/// Reusable network image with disk + memory caching and RAM-safe decoding.
///
/// Uses [CachedNetworkImage] under the hood for automatic disk/memory caching.
/// [memCacheWidth] / [memCacheHeight] cap the decoded bitmap size in RAM so
/// full-resolution images (e.g. 3000×4000 px) don't waste tens of MB each.
class NetworkImageView extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? errorWidget;
  final Widget Function(BuildContext context, ImageChunkEvent? progress)?
      loadingBuilder;

  /// Max decoded width in pixels kept in memory.
  /// Defaults to 400 px — enough for list thumbnails and cards.
  final int? memCacheWidth;

  /// Max decoded height in pixels kept in memory.
  final int? memCacheHeight;

  /// Accessibility label for screen readers.
  final String? semanticLabel;

  const NetworkImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorWidget,
    this.loadingBuilder,
    this.memCacheWidth = 400,
    this.memCacheHeight,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _defaultError();
    }

    if (imageUrl.startsWith(ProductImageUtils.assetUriPrefix)) {
      final path =
          imageUrl.substring(ProductImageUtils.assetUriPrefix.length).trim();
      if (path.isEmpty) {
        return errorWidget ?? _defaultError();
      }
      final asset = Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? _defaultError(),
      );
      if (semanticLabel != null) {
        return Semantics(label: semanticLabel, image: true, child: asset);
      }
      return asset;
    }

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) {
        if (loadingBuilder case final builder?) return builder(context, null);
        return Container(
          color: AppColors.surfaceLight,
          child: const Center(
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColors.textTertiary),
            ),
          ),
        );
      },
      errorWidget: (context, url, error) {
        return errorWidget ?? _defaultError();
      },
    );

    if (semanticLabel != null) {
      return Semantics(label: semanticLabel, image: true, child: image);
    }
    return image;
  }

  Widget _defaultError() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
