import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Thumbnail with optional delete control (hidden when [canDelete] is false).
class ScreenshotThumb extends StatelessWidget {
  const ScreenshotThumb({
    super.key,
    required this.path,
    required this.canDelete,
    required this.onDelete,
    this.aspectRatio,
    this.borderRadius = 10,
  });

  final String path;
  final bool canDelete;
  final VoidCallback onDelete;
  final double? aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.mist,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );

    final stacked = Stack(
      fit: StackFit.expand,
      children: [
        image,
        if (canDelete)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (aspectRatio == null) return stacked;
    return AspectRatio(aspectRatio: aspectRatio!, child: stacked);
  }
}
