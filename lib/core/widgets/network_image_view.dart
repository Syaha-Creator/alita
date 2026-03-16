import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _defaultError();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      placeholder: (context, url) {
        if (loadingBuilder != null) return loadingBuilder!(context, null);
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
