import 'package:flutter/material.dart';

import '../models/food_prediction.dart';
import '../models/meal.dart';
import '../services/mealdb_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.prediction});

  final FoodPrediction prediction;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _mealDbService = MealDbService();
  late final Future<Meal?> _mealFuture;

  @override
  void initState() {
    super.initState();
    _mealFuture = widget.prediction.isRecognized
        ? _mealDbService.searchByName(widget.prediction.label)
        : Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final prediction = widget.prediction;

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Prediksi')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              prediction.image,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          _buildPredictionCard(context, prediction),
          const SizedBox(height: 24),
          Text('Referensi Resep', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!prediction.isRecognized)
            const _InfoBanner(
              text: 'Model tidak cukup yakin mengenali makanan pada gambar ini, '
                  'sehingga referensi resep tidak dapat dicari.',
            )
          else
            FutureBuilder<Meal?>(
              future: _mealFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _InfoBanner(text: 'Gagal memuat data dari MealDB: ${snapshot.error}');
                }
                final meal = snapshot.data;
                if (meal == null) {
                  return _InfoBanner(
                    text: 'Tidak ditemukan referensi resep untuk '
                        '"${prediction.label}" di MealDB.',
                  );
                }
                return _MealDetail(meal: meal);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(BuildContext context, FoodPrediction prediction) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Makanan Terdeteksi', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    prediction.isRecognized ? prediction.label : 'Tidak Terdeteksi',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    prediction.confidencePercentText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'confidence',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealDetail extends StatelessWidget {
  const _MealDetail({required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (meal.thumbnailUrl.isNotEmpty)
                Image.network(meal.thumbnailUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name, style: theme.textTheme.titleLarge),
                    if (meal.category != null || meal.area != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (meal.category != null) Chip(label: Text(meal.category!)),
                          if (meal.area != null) Chip(label: Text(meal.area!)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Bahan-bahan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: meal.ingredients
                  .map(
                    (ing) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 8),
                      title: Text(ing.name),
                      trailing: Text(ing.measure, style: theme.textTheme.bodySmall),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Langkah Pembuatan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(meal.instructions, style: theme.textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
