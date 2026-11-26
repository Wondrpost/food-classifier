import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Input model food_classifier.tflite (AIY Food V1): 192x192 RGB uint8,
/// tanpa normalisasi tambahan karena model sudah di-quantize.
const kModelInputSize = 192;

/// Top-level function supaya bisa dijalankan lewat `compute()` di isolate
/// terpisah dari UI thread.
Uint8List preprocessImageBytes(Uint8List fileBytes) {
  final decoded = img.decodeImage(fileBytes);
  if (decoded == null) {
    throw const FormatException('Gagal membaca berkas gambar.');
  }

  final resized = img.copyResize(
    decoded,
    width: kModelInputSize,
    height: kModelInputSize,
    interpolation: img.Interpolation.linear,
  );

  final buffer = Uint8List(kModelInputSize * kModelInputSize * 3);
  var offset = 0;
  for (var y = 0; y < kModelInputSize; y++) {
    for (var x = 0; x < kModelInputSize; x++) {
      final pixel = resized.getPixel(x, y);
      buffer[offset++] = pixel.r.toInt();
      buffer[offset++] = pixel.g.toInt();
      buffer[offset++] = pixel.b.toInt();
    }
  }
  return buffer;
}
