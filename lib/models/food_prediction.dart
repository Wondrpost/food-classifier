import 'dart:io';

class FoodPrediction {
  final File image;
  final String label;
  final double confidence;

  const FoodPrediction({
    required this.image,
    required this.label,
    required this.confidence,
  });

  String get confidencePercentText => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Model food classifier mengembalikan kelas "__background__" ketika
  /// tidak ada makanan yang cukup meyakinkan terdeteksi pada gambar.
  bool get isRecognized => label != '__background__' && confidence > 0;
}
