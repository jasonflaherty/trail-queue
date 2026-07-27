import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../colors.dart';

class PhotoGallery extends StatelessWidget {
  const PhotoGallery({super.key, required this.urls, this.height = 96});

  final List<String> urls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CachedNetworkImage(
              imageUrl: urls[index],
              width: height * 1.25,
              height: height,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: height * 1.25,
                color: TqColors.sand,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}
