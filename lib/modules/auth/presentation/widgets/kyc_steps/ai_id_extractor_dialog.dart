import 'dart:io';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/ai_service.dart';

/// Dialog that shows AI extraction progress and results
/// Provides user option to accept or manually fill the data
class AiIdExtractorDialog extends StatefulWidget {
  final File idImage;
  final IDExtractionService extractionService;
  final Function(Map<String, dynamic> extractedData) onAccept;
  final VoidCallback onDecline;

  const AiIdExtractorDialog({
    super.key,
    required this.idImage,
    required this.extractionService,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<AiIdExtractorDialog> createState() => _AiIdExtractorDialogState();
}

class _AiIdExtractorDialogState extends State<AiIdExtractorDialog> {
  bool _isExtracting = true;
  Map<String, dynamic>? _extractedData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _extractData();
  }

  // Perform AI extraction on the uploaded ID image
  Future<void> _extractData() async {
    try {
      // Call AI service to extract ID information
      final result = await widget.extractionService.extractIDInfo(widget.idImage);

      setState(() {
        _extractedData = result;
        _isExtracting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isExtracting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _isExtracting
            ? _buildLoadingState(theme, isDark)
            : _errorMessage != null
                ? _buildErrorState(theme, isDark)
                : _buildResultState(theme, isDark),
      ),
    );
  }

  // Shows loading spinner while AI extracts data
  Widget _buildLoadingState(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primary.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.2),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(height: 24),
        Text(
          'AI is Reading Your ID',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Extracting information from your document...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Shows error message if extraction fails
  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: ColorConstants.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Extraction Failed',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Unable to extract ID information',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDecline();
            },
            child: const Text('Fill Manually'),
          ),
        ),
      ],
    );
  }

  // Shows extracted data with option to accept or decline
  Widget _buildResultState(ThemeData theme, bool isDark) {
    final confidence = (_extractedData!['confidence'] as double) * 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorConstants.primary, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Extracted',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Confidence: ${confidence.toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: confidence >= 80
                          ? ColorConstants.success
                          : ColorConstants.warning,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Display extracted information
        _buildDataField(theme, isDark, 'ID Type', _extractedData!['id_type']),
        _buildDataField(theme, isDark, 'ID Number', _extractedData!['id_number']),
        if (_extractedData!.containsKey('full_name'))
          _buildDataField(theme, isDark, 'Full Name', _extractedData!['full_name']),
        if (_extractedData!.containsKey('date_of_birth'))
          _buildDataField(theme, isDark, 'Date of Birth', _extractedData!['date_of_birth']),
        if (_extractedData!.containsKey('address'))
          _buildDataField(theme, isDark, 'Address', _extractedData!['address']),

        const SizedBox(height: 24),

        // Warning if confidence is low
        if (confidence < 80)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ColorConstants.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ColorConstants.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: ColorConstants.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Low confidence. Please verify the information.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDecline();
                },
                child: const Text('Fill Manually'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onAccept(_extractedData!);
                },
                child: const Text('Use This Data'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper to build data field display
  Widget _buildDataField(ThemeData theme, bool isDark, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
