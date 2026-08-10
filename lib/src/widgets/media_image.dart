import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/local_post_store.dart';

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (LocalPostStore.isLocalPath(path)) {
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: errorBuilder,
      );
    }
    return CachedNetworkImage(
      imageUrl: path,
      fit: fit,
      width: width,
      height: height,
      color: color,
      colorBlendMode: colorBlendMode,
      errorWidget: errorBuilder != null
          ? (context, url, error) => errorBuilder!(context, error, null)
          : null,
    );
  }
}
