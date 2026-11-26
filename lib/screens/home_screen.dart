import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../services/classifier_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.classifier});

  final ClassifierService classifier;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  File? _selectedImage;
  bool _isClassifying = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _errorMessage = null);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return;

      final cropped = await _cropImage(picked.path);
      if (cropped == null) return;

      setState(() => _selectedImage = File(cropped.path));
    } catch (e) {
      setState(() => _errorMessage = 'Gagal mengambil gambar: $e');
    }
  }

  Future<CroppedFile?> _cropImage(String sourcePath) {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Potong Gambar Makanan',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Potong Gambar Makanan'),
      ],
    );
  }

  Future<void> _analyzeImage() async {
    final image = _selectedImage;
    if (image == null) return;

    setState(() {
      _isClassifying = true;
      _errorMessage = null;
    });

    try {
      final prediction = await widget.classifier.classify(image);
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(prediction: prediction),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Gagal menganalisis gambar: $e');
    } finally {
      if (mounted) setState(() => _isClassifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Classifier')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(child: _buildPreview()),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isClassifying ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isClassifying ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedImage == null || _isClassifying ? null : _analyzeImage,
                  icon: _isClassifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isClassifying ? 'Menganalisis...' : 'Analisis Gambar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final image = _selectedImage;
    if (image == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Ambil atau pilih foto makanan\nuntuk diidentifikasi', textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(image, fit: BoxFit.cover, width: double.infinity),
    );
  }
}
