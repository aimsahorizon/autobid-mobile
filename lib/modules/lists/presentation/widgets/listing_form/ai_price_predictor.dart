import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../../../core/constants/color_constants.dart';
import '../../../../../../core/services/price_prediction_service.dart';
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
  double _confidence = 0;
  String _method = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _predictPrice();
  }

  Future<void> _predictPrice() async {
    try {
      final service = GetIt.instance<PricePredictionService>();

      final vehicleData = {
        'brand': widget.draft.brand ?? '',
        'year': widget.draft.year ?? DateTime.now().year,
        'mileage': widget.draft.mileage ?? 50000,
        'condition': widget.draft.condition ?? 'Good',
        'transmission': widget.draft.transmission ?? 'Automatic',
      };

      final result = await service.predictPrice(vehicleData);
      final price = (result['predicted_price'] as num).toDouble();

      setState(() {
        _predictedPrice = price;
        _minPrice = price * 0.92;
        _maxPrice = price * 1.08;
        _confidence = (result['confidence'] as num).toDouble();
        _method = result['method'] as String;
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
            'AI-powered valuation using on-device neural network.',
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _method == 'ai_tflite' ? Icons.memory : Icons.calculate,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                _method == 'ai_tflite'
                    ? 'TFLite Neural Network • ${(_confidence * 100).toInt()}% confidence'
                    : 'Heuristic Estimate',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
