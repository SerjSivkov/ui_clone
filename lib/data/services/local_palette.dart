import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Args for [extractDominantColors] (isolate-safe).
class DominantColorArgs {
  const DominantColorArgs({
    required this.bytes,
    this.maxColors = 6,
  });

  final Uint8List bytes;
  final int maxColors;
}

class DominantColor {
  const DominantColor({
    required this.hex,
    required this.count,
  });

  final String hex;
  final int count;
}

/// Downscale + quantize pixels → top HEX colors by frequency.
/// Safe for `compute`.
List<DominantColor> extractDominantColors(DominantColorArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return const [];

  var image = decoded;
  const target = 64;
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > target) {
    if (image.width >= image.height) {
      image = img.copyResize(
        image,
        width: target,
        interpolation: img.Interpolation.average,
      );
    } else {
      image = img.copyResize(
        image,
        height: target,
        interpolation: img.Interpolation.average,
      );
    }
  }

  final buckets = <int, int>{};
  for (final pixel in image) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final a = pixel.a.toInt();
    if (a < 200) continue;
    // 4-bit quantization per channel → 4096 buckets max.
    final key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    buckets[key] = (buckets[key] ?? 0) + 1;
  }

  final sorted = buckets.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final maxColors = args.maxColors.clamp(1, 12);
  final out = <DominantColor>[];
  for (final entry in sorted) {
    if (out.length >= maxColors) break;
    final key = entry.key;
    final r = ((key >> 8) & 0xF) * 17;
    final g = ((key >> 4) & 0xF) * 17;
    final b = (key & 0xF) * 17;
    out.add(
      DominantColor(
        hex: '#${_byteHex(r)}${_byteHex(g)}${_byteHex(b)}',
        count: entry.value,
      ),
    );
  }
  return out;
}

String _byteHex(int v) => v.clamp(0, 255).toRadixString(16).padLeft(2, '0');

/// Merge similar colors across screenshots (same quantized bucket).
List<DominantColor> mergeDominantColors(
  List<DominantColor> colors, {
  int maxColors = 8,
}) {
  final map = <String, int>{};
  for (final c in colors) {
    final key = c.hex.toUpperCase();
    map[key] = (map[key] ?? 0) + c.count;
  }
  final sorted = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in sorted.take(maxColors.clamp(1, 12)))
      DominantColor(hex: e.key, count: e.value),
  ];
}
