import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Arguments for [compressJpegBytes] (must be sendable to `compute`).
class JpegCompressArgs {
  const JpegCompressArgs({
    required this.bytes,
    required this.quality,
    required this.maxSide,
  });

  final Uint8List bytes;
  final int quality;
  final int maxSide;
}

/// Decode → optional downscale by longest side → JPEG encode.
/// Safe to run in a background isolate via `compute`.
Uint8List compressJpegBytes(JpegCompressArgs args) {
  final quality = args.quality.clamp(40, 95);
  final maxSide = args.maxSide.clamp(512, 2048);
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) {
    return args.bytes;
  }

  var image = decoded;
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxSide) {
    if (image.width >= image.height) {
      image = img.copyResize(
        image,
        width: maxSide,
        interpolation: img.Interpolation.linear,
      );
    } else {
      image = img.copyResize(
        image,
        height: maxSide,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}
