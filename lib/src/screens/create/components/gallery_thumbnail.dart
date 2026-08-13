import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../adaptive_colors.dart';

class GalleryThumbnail extends StatelessWidget {
  const GalleryThumbnail({
    super.key,
    required this.asset,
    required this.onTap,
  });

  final AssetEntity asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVideo = asset.type == AssetType.video;
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<Uint8List?>(
        future: asset.thumbnailDataWithSize(const ThumbnailSize(600, 600)),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return Container(
              color: context.backgroundColor,
              alignment: Alignment.center,
              child: Icon(
                isVideo ? Icons.movie_outlined : Icons.image_outlined,
                color: context.textSecondaryColor,
              ),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(data, fit: BoxFit.cover),
              if (isVideo)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
