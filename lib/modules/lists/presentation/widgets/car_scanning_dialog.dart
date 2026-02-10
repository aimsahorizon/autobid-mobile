import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/services/car_detection_service.dart';

/// A dialog that allows users to capture/upload a car image and get AI tags.
class CarScanningDialog extends StatefulWidget {
  final Function(Map<String, dynamic> result) onTagsDetected;

  const CarScanningDialog({super.key, required this.onTagsDetected});

  @override
  State<CarScanningDialog> createState() => _CarScanningDialogState();
}

class _CarScanningDialogState extends State<CarScanningDialog> {
  final _carService = CarDetectionService();
  final _picker = ImagePicker();
  
  File? _imageFile;
  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _isScanning = true;
        _scanResult = null;
      });

      // Run AI Detection
      final result = await _carService.detectCarFromImageReal(picked.path);

      setState(() {
        _scanResult = result;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Car Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Image Area
            GestureDetector(
              onTap: _scanResult == null && !_isScanning ? () => _pickImage(ImageSource.camera) : null,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                            Text('Tap to take photo'),
                          ],
                        )
                      : null,
              ),
            ),

            const SizedBox(height: 16),

            // Results Area
            if (_scanResult != null) ...[
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: ColorConstants.success),
                title: Text(
                  "${_scanResult!['brand']} ${_scanResult!['model']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Confidence: ${( (_scanResult!['confidence'] as double) * 100).toStringAsFixed(1)}%"
                ),
              ),
              Wrap(
                spacing: 8,
                children: (_scanResult!['tags'] as List).map((tag) {
                  return Chip(
                    label: Text(tag.toString(), style: const TextStyle(fontSize: 10)),
                    backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
                    padding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onTagsDetected(_scanResult!);
                    Navigator.pop(context);
                  },
                  child: const Text('Use These Tags'),
                ),
              )
            ] else if (!_isScanning) ...[
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                 children: [
                   TextButton.icon(
                     onPressed: () => _pickImage(ImageSource.camera),
                     icon: const Icon(Icons.camera_alt),
                     label: const Text('Camera'),
                   ),
                   TextButton.icon(
                     onPressed: () => _pickImage(ImageSource.gallery),
                     icon: const Icon(Icons.photo_library),
                     label: const Text('Gallery'),
                   ),
                 ],
               ),
            ],
          ],
        ),
      ),
    );
  }
}
