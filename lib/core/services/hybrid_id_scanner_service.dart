import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:autobid_mobile/core/utils/id_parser_util.dart';
import 'package:autobid_mobile/core/utils/mrz_parser_util.dart';
import 'ai_id_extraction_service.dart'; // Reuse ExtractedIdData model

/// Advanced Hybrid Scanner (OCR + Barcode + MRZ)
class HybridIdScannerService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.pdf417, BarcodeFormat.qrCode]);

  /// Main entry point: Scans an image for ANY data (Barcode first, then OCR)
  Future<ExtractedIdData> scanImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // 1. Try Barcode (Highest Accuracy for DL Back / PhilSys QR)
    try {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        final data = _processBarcode(barcodes.first);
        if (data != null) return data;
      }
    } catch (e) {
      // Ignore barcode error, continue to OCR
    }

    // 2. Try OCR (Text/MRZ)
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final text = recognizedText.text;

    // 3. Check for MRZ (Passport - High Accuracy)
    if (text.contains('P<PHL')) {
      final mrzData = MrzParserUtil.parse(text);
      if (mrzData.isNotEmpty) {
        return ExtractedIdData(
          firstName: mrzData['firstName'],
          lastName: mrzData['lastName'],
          idNumber: mrzData['idNumber'],
          dateOfBirth: _parseDate(mrzData['dateOfBirth']),
          sex: mrzData['sex'],
        );
      }
    }

    // 4. Fallback to Standard Regex/Spatial Parsing (Front ID)
    final parsed = IdParserUtil.parse(recognizedText);
    return ExtractedIdData(
      firstName: parsed['firstName'],
      middleName: parsed['middleName'],
      lastName: parsed['lastName'],
      idNumber: parsed['idNumber'],
      dateOfBirth: _parseDate(parsed['dateOfBirth']),
    );
  }

  ExtractedIdData? _processBarcode(Barcode barcode) {
    final raw = barcode.rawValue;
    if (raw == null) return null;

    // A. Driver's License (PDF417)
    if (barcode.format == BarcodeFormat.pdf417) {
      final map = IdParserUtil.parseDriverLicenseBarcode(raw);
      if (map.isNotEmpty) {
        return ExtractedIdData(
          idNumber: map['idNumber'],
          firstName: map['firstName'],
          lastName: map['lastName'],
          middleName: map['middleName'],
          dateOfBirth: _parseDate(map['dateOfBirth']),
        );
      }
    }

    // B. PhilSys (QR) - Often encrypted, but sometimes contains simple JSON/Text
    // If it's a verification URL, we can't extract PII.
    // If it contains "ID-...", we might get lucky.
    // For now, we rely on OCR for PhilSys front.
    
    return null;
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}
