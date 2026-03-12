import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../core/constants/color_constants.dart';
import '../../../domain/entities/listing_draft_entity.dart';

class AiPricePredictor extends StatefulWidget {
  final ListingDraftEntity draft;
  final Function(double price) onApplyPrice;

  const AiPricePredictor({
    super.key,
    required this.draft,
    required this.onApplyPrice,
  });

  @override
  State<AiPricePredictor> createState() => _AiPricePredictorState();
}

class _AiPricePredictorState extends State<AiPricePredictor> {
  bool _isLoading = true;
  double? _predictedPrice;
  double? _minPrice;
  double? _maxPrice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _predictPrice();
  }

  Future<void> _predictPrice() async {
    try {
      // 1. Load Metadata
      final jsonStr = await rootBundle.loadString(
        'assets/ai/pricing_metadata.json',
      );
      final Map<String, dynamic> db = json.decode(jsonStr);

      final key = '${widget.draft.brand}_${widget.draft.model}'
          .toLowerCase()
          .replaceAll(' ', '_');

      final yearKey = widget.draft.year.toString();

      if (!db.containsKey(key) || !db[key].containsKey(yearKey)) {
        throw Exception('Not enough market data for this specific model.');
      }

      final stats = db[key][yearKey];
      double basePrice = (stats['price'] as num).toDouble();

      // 2. Apply Adjustments (Logic-based AI)

      // Mileage Adjustment (Avg is ~10k/year)
      final age = DateTime.now().year - (widget.draft.year ?? 2020);
      final expectedMileage = age * 10000;
      final actualMileage = widget.draft.mileage ?? expectedMileage;

      if (actualMileage > expectedMileage * 1.5) {
        basePrice *= 0.90; // -10% for high mileage
      } else if (actualMileage < expectedMileage * 0.5) {
        basePrice *= 1.05; // +5% for low mileage
      }

      // Condition Adjustment
      if (widget.draft.condition == 'Excellent') basePrice *= 1.05;
      if (widget.draft.condition == 'Fair') basePrice *= 0.90;
      if (widget.draft.condition == 'Needs Repair') basePrice *= 0.70;

      setState(() {
        _predictedPrice = basePrice;
        _minPrice = basePrice * 0.95;
        _maxPrice = basePrice * 1.05;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: LinearProgressIndicator());
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'AI Price Estimate Unavailable: $_error',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, color: ColorConstants.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Market Valuation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Based on ${widget.draft.year} ${widget.draft.brand} ${widget.draft.model} market data.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estimated Range', style: TextStyle(fontSize: 10)),
                  Text(
                    '₱${(_minPrice! / 1000).toStringAsFixed(0)}k - ₱${(_maxPrice! / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => widget.onApplyPrice(_predictedPrice!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Apply Suggested'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
