import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ui_clone/data/services/local_palette.dart';

void main() {
  test('extractDominantColors returns hex from solid image', () {
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgb8(15, 139, 141));
    final bytes = Uint8List.fromList(img.encodePng(image));

    final colors = extractDominantColors(
      DominantColorArgs(bytes: bytes, maxColors: 3),
    );

    expect(colors, isNotEmpty);
    expect(colors.first.hex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
    // 4-bit quantization: #0F8B8D → #008888
    expect(colors.first.hex.toUpperCase(), '#008888');
  });

  test('mergeDominantColors keeps top by count', () {
    final merged = mergeDominantColors(
      const [
        DominantColor(hex: '#111111', count: 2),
        DominantColor(hex: '#ABCDEF', count: 10),
        DominantColor(hex: '#111111', count: 3),
      ],
      maxColors: 2,
    );
    expect(merged.first.hex, '#ABCDEF');
    expect(merged.first.count, 10);
    expect(merged[1].hex, '#111111');
    expect(merged[1].count, 5);
  });
}
