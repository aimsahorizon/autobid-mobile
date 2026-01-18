import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/ai_service.dart';

class AiPricePredictor extends StatefulWidget {
  final String? brand;
  final String? model;
  final int? year;
  final int? mileage;
  final String? condition;
  final void Function(double price) onAccept;

  const AiPricePredictor({
    super.key,
    required this.brand,
    required this.model,
    required this.year,
    required this.mileage,
    required this.condition,
    required this.onAccept,
  });

  @override
  State<AiPricePredictor> createState() => _AiPricePredictorState();
}

class _AiPricePredictorState extends State<AiPricePredictor> {
  final PricePredictionService _aiService = PricePredictionService(useEdgeModel: true);
  bool _isLoading = false;
  double? _predictedPrice;
  Map<String, dynamic>? _priceBreakdown;

  @override
  void initState() {
    super.initState();
    _predictPrice();
  }

  @override
  void didUpdateWidget(AiPricePredictor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.brand != oldWidget.brand ||
        widget.model != oldWidget.model ||
        widget.year != oldWidget.year ||
        widget.mileage != oldWidget.mileage ||
        widget.condition != oldWidget.condition) {
      _predictPrice();
    }
  }

  // Calls AI service to predict vehicle price
  Future<void> _predictPrice() async {
    // Check if all required fields are filled
    if (widget.brand == null ||
        widget.model == null ||
        widget.year == null ||
        widget.mileage == null ||
        widget.condition == null) {
      setState(() {
        _predictedPrice = null;
        _priceBreakdown = null;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare vehicle data for AI service
      final vehicleData = {
        'brand': widget.brand!,
        'model': widget.model!,
        'year': widget.year!,
        'mileage': widget.mileage!,
        'condition': widget.condition!,
      };

      // Call AI service to predict price
      final result = await _aiService.predictPrice(vehicleData);

      setState(() {
        _predictedPrice = result['predicted_price'];
        _priceBreakdown = result['factors'];
        _isLoading = false;
      });
    } catch (e) {
      // Handle prediction error
      setState(() {
        _predictedPrice = null;
        _priceBreakdown = null;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Price prediction failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.surfaceDark
              : ColorConstants.backgroundSecondaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is analyzing your vehicle...',
              style: TextStyle(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_predictedPrice == null) {
      return const SizedBox.shrink();
    }

    // Calculate suggested reserve price (10% higher than predicted)
    final suggestedReserve = _predictedPrice! * 1.1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primary.withValues(alpha: 0.15),
            ColorConstants.primary.withValues(alpha: 0.08),
            Colors.purple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sparkle effect
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ColorConstants.primary, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Price Recommendation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Smart pricing based on market analysis',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Starting Price Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : Colors.white,
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
                          Icon(
                            Icons.play_arrow,
                            color: ColorConstants.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Suggested Starting Price',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${_formatPrice(_predictedPrice!)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Reserve Price Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Suggested Reserve Price',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${_formatPrice(suggestedReserve)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum acceptable price (+10%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Vehicle info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? ColorConstants.surfaceDark
                            : ColorConstants.backgroundSecondaryLight)
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.year} ${widget.brand} ${widget.model} • ${_formatNumber(widget.mileage!)} km • ${widget.condition}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Accept button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onAccept(_predictedPrice!),
                    icon: const Icon(Icons.check_circle, size: 22),
                    label: const Text(
                      'Use AI Suggestions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: ColorConstants.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
