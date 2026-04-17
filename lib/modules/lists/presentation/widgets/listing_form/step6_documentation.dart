import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import '../../../domain/usecases/validate_plate_number_usecase.dart';
import 'form_field_widget.dart';
import 'province_city_picker.dart';

class Step6Documentation extends StatefulWidget {
  final ListingDraftController controller;

  const Step6Documentation({super.key, required this.controller});

  @override
  State<Step6Documentation> createState() => _Step6DocumentationState();
}

class _Step6DocumentationState extends State<Step6Documentation> {
  late TextEditingController _plateLetterController;
  late TextEditingController _plateNumberController;
  late TextEditingController _chassisNumberController;
  final _plateLetterFocus = FocusNode();
  final _plateNumberFocus = FocusNode();
  final _validatePlateUseCase = GetIt.I<ValidatePlateNumberUseCase>();

  String? _province;
  String? _city;
  String? _barangay;
  String? _orcrStatus;
  String? _registrationStatus;
  DateTime? _registrationExpiry;
  bool _isUploadingDeed = false;

  // Validation State
  Timer? _debounce;
  String? _plateError;
  bool _isValidatingPlate = false;
  bool _isPlateValid = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;

    // Parse existing plate number into letter and number parts
    final existingPlate = draft.plateNumber ?? '';
    final parts = existingPlate.split(' ');
    _plateLetterController = TextEditingController(
      text: parts.isNotEmpty ? parts[0] : '',
    );
    _plateNumberController = TextEditingController(
      text: parts.length > 1 ? parts[1] : '',
    );
    _chassisNumberController = TextEditingController(
      text: draft.chassisNumber ?? '',
    );

    _province = draft.province;
    _city = draft.cityMunicipality;
    _barangay = draft.barangay;

    _orcrStatus = draft.orcrStatus;
    _registrationStatus = draft.registrationStatus;
    _registrationExpiry = draft.registrationExpiry;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDraft();
    });

    _plateLetterController.addListener(_onPlateChanged);
    _plateNumberController.addListener(_onPlateChanged);
    _chassisNumberController.addListener(_updateDraft);
    widget.controller.addListener(_onControllerChanged);

    // Initial validation if existing value
    if (_combinedPlate.isNotEmpty) {
      _validatePlate(_combinedPlate);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final draft = widget.controller.currentDraft;
    if (draft == null) return;

    if (_province != draft.province ||
        _city != draft.cityMunicipality ||
        _barangay != draft.barangay ||
        _orcrStatus != draft.orcrStatus ||
        _registrationStatus != draft.registrationStatus ||
        _registrationExpiry != draft.registrationExpiry) {
      setState(() {
        _province = draft.province;
        _city = draft.cityMunicipality;
        _barangay = draft.barangay;
        _orcrStatus = draft.orcrStatus;
        _registrationStatus = draft.registrationStatus;
        _registrationExpiry = draft.registrationExpiry;
      });
    }

    // Sync plate number
    final existingPlate = draft.plateNumber ?? '';
    final parts = existingPlate.split(' ');
    final newLetters = parts.isNotEmpty ? parts[0] : '';
    final newNumbers = parts.length > 1 ? parts[1] : '';
    if (_plateLetterController.text != newLetters ||
        _plateNumberController.text != newNumbers) {
      _plateLetterController.removeListener(_onPlateChanged);
      _plateNumberController.removeListener(_onPlateChanged);
      _plateLetterController.text = newLetters;
      _plateNumberController.text = newNumbers;
      _plateLetterController.addListener(_onPlateChanged);
      _plateNumberController.addListener(_onPlateChanged);
    }

    // Sync chassis number
    final newChassis = draft.chassisNumber ?? '';
    if (_chassisNumberController.text != newChassis) {
      _chassisNumberController.text = newChassis;
    }
  }

  String get _combinedPlate {
    final letters = _plateLetterController.text.trim().toUpperCase();
    final numbers = _plateNumberController.text.trim();
    if (letters.isEmpty && numbers.isEmpty) return '';
    return '$letters $numbers';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _plateLetterController.removeListener(_onPlateChanged);
    _plateNumberController.removeListener(_onPlateChanged);
    _chassisNumberController.removeListener(_updateDraft);
    _plateLetterController.dispose();
    _plateNumberController.dispose();
    _chassisNumberController.dispose();
    _plateLetterFocus.dispose();
    _plateNumberFocus.dispose();
    super.dispose();
  }

  void _onPlateChanged() {
    // Force uppercase for letters
    final letterText = _plateLetterController.text.toUpperCase();
    if (letterText != _plateLetterController.text) {
      _plateLetterController.value = _plateLetterController.value.copyWith(
        text: letterText,
        selection: TextSelection.collapsed(offset: letterText.length),
      );
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      final combined = _combinedPlate;
      if (combined.trim().isNotEmpty) {
        _validatePlate(combined);
      } else {
        setState(() {
          _plateError = null;
          _isPlateValid = false;
          _isValidatingPlate = false;
        });
      }
    });

    // Update draft immediately for simple text change
    _updateDraft();
  }

  Future<void> _validatePlate(String value) async {
    if (value.isEmpty) {
      setState(() {
        _plateError = null;
        _isPlateValid = false;
        _isValidatingPlate = false;
      });
      return;
    }

    setState(() => _isValidatingPlate = true);

    final error = await _validatePlateUseCase(
      value,
      widget.controller.currentDraft!.sellerId,
    );

    if (mounted) {
      setState(() {
        _isValidatingPlate = false;
        _plateError = error;
        _isPlateValid = error == null;
      });

      // If validation fails, update draft to clear invalid plate?
      // Or keep it but block submission later?
      // For now, we update draft anyway so typed value persists,
      // but UI shows error.
      _updateDraft();
    }
  }

  void _unfocusPlateFields() {
    _plateLetterFocus.unfocus();
    _plateNumberFocus.unfocus();
  }

  void _updateDraft() {
    final draft = widget.controller.currentDraft!;
    widget.controller.updateDraft(
      draft.copyWith(
        lastSaved: DateTime.now(),
        plateNumber: _combinedPlate.isEmpty ? null : _combinedPlate,
        chassisNumber: _chassisNumberController.text.trim().isEmpty
            ? null
            : _chassisNumberController.text.trim().toUpperCase(),
        orcrStatus: _orcrStatus,
        registrationStatus: _registrationStatus,
        registrationExpiry: _registrationExpiry,
        province: _province,
        cityMunicipality: _city,
        barangay: _barangay,
        isPlateValid: _isPlateValid,
        isComplete: draft.isComplete && _isPlateValid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 7: Documentation & Locations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _plateLetterController,
          focusNode: _plateLetterFocus,
          label: 'Plate Letters *',
          hint: 'e.g., ABC',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
            LengthLimitingTextInputFormatter(3),
          ],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length != 3) return 'Must be exactly 3 letters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _plateNumberController,
          focusNode: _plateNumberFocus,
          label: 'Plate Number *',
          hint: 'e.g., 1234',
          errorText: _plateError,
          suffix: _isValidatingPlate
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_isPlateValid && _plateNumberController.text.isNotEmpty)
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length != 4) return 'Must be exactly 4 digits';
            return _plateError;
          },
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _chassisNumberController,
          label: 'Chassis Number (VIN)',
          hint: 'e.g., 1HGBH41JXMN109186',
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-HJ-NPR-Za-hj-npr-z0-9]'),
            ),
            LengthLimitingTextInputFormatter(17),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toUpperCase());
            }),
          ],
          validator: (v) {
            if (v == null || v.isEmpty) return null; // Optional field
            if (v.length != 17) return 'VIN must be exactly 17 characters';
            if (!RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(v)) {
              return 'Invalid VIN format';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'OR/CR Status *',
          value: _orcrStatus,
          items: const ['Available', 'In Process', 'Lost', 'Not Available'],
          onChanged: (v) {
            _unfocusPlateFields();
            setState(() => _orcrStatus = v);
            _updateDraft();
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'Registration Status',
          value: _registrationStatus,
          items: const ['Current', 'Expired', 'Renewal Pending'],
          onChanged: (v) {
            _unfocusPlateFields();
            setState(() {
              _registrationStatus = v;
              // Clear expiry if status changed so user picks a valid date
              _registrationExpiry = null;
            });
            _updateDraft();
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            _unfocusPlateFields();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));

            DateTime initialDate;
            DateTime firstDate;
            DateTime lastDate;

            if (_registrationStatus == 'Current') {
              // Must not accept date before today
              firstDate = today;
              lastDate = today.add(const Duration(days: 365 * 5));
              initialDate =
                  _registrationExpiry ?? today.add(const Duration(days: 365));
              if (initialDate.isBefore(firstDate)) initialDate = firstDate;
            } else if (_registrationStatus == 'Expired') {
              // Must not accept date from today onward, only yesterday and before
              firstDate = DateTime(2000);
              lastDate = yesterday;
              initialDate = _registrationExpiry ?? yesterday;
              if (initialDate.isAfter(lastDate)) initialDate = lastDate;
            } else {
              // Renewal Pending or null — any date
              firstDate = DateTime(2000);
              lastDate = today.add(const Duration(days: 365 * 5));
              initialDate =
                  _registrationExpiry ?? today.add(const Duration(days: 365));
            }

            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: lastDate,
            );
            if (picked != null) {
              setState(() => _registrationExpiry = picked);
              _updateDraft();
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Registration Expiry',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _registrationExpiry != null
                      ? '${_registrationExpiry!.month}/${_registrationExpiry!.day}/${_registrationExpiry!.year}'
                      : 'Select date',
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Location Picker
        LocationPicker(
          province: _province,
          city: _city,
          barangay: _barangay,
          onChanged: (province, city, barangay) {
            _unfocusPlateFields();
            setState(() {
              _province = province;
              _city = city;
              _barangay = barangay;
            });
            _updateDraft();
          },
          provinceValidator: (v) => v == null ? 'Required' : null,
          cityValidator: (v) => v == null ? 'Required' : null,
          barangayValidator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        _buildDeedOfSaleSection(context),
      ],
    );
  }

  // ─── Deed of Sale ──────────────────────────────────────────────────────────

  Future<void> _pickDeedOfSale(BuildContext context) async {
    setState(() => _isUploadingDeed = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final extension = (picked.extension ?? '').toLowerCase();
      const allowed = ['jpg', 'jpeg', 'png', 'pdf'];
      if (!allowed.contains(extension)) {
        if (context.mounted) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Unsupported format. Use JPG, PNG, or PDF.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final path = picked.path;
      if (path == null) return;

      final url = await widget.controller.uploadDeedOfSale(path);
      if (context.mounted) {
        if (url != null) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            const SnackBar(
              content: Text('Deed of sale uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                widget.controller.errorMessage ??
                    'Failed to upload deed of sale',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDeed = false);
    }
  }

  Future<void> _removeDeedOfSale(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Deed of Sale?'),
        content: const Text(
          'Are you sure you want to remove the uploaded document?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final ok = await widget.controller.removeDeedOfSale();
    if (context.mounted) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Deed of sale removed' : 'Failed to remove'),
          backgroundColor: ok ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Widget _buildDeedOfSaleSection(BuildContext context) {
    final deedUrl = widget.controller.currentDraft?.deedOfSaleUrl;
    final hasDoc = deedUrl != null && deedUrl.isNotEmpty;
    final isPdf = hasDoc && deedUrl.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deed of Sale (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Accepted formats: JPG, PNG, PDF',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (hasDoc) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image,
                  color: isPdf ? Colors.red : Colors.blue,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPdf ? 'PDF Document' : 'Image Document',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Uploaded',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove',
                  onPressed: () => _removeDeedOfSale(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isUploadingDeed
                  ? null
                  : () => _pickDeedOfSale(context),
              icon: _isUploadingDeed
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.swap_horiz),
              label: Text(
                _isUploadingDeed ? 'Uploading...' : 'Replace Document',
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingDeed
                  ? null
                  : () => _pickDeedOfSale(context),
              icon: _isUploadingDeed
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isUploadingDeed ? 'Uploading...' : 'Upload Deed of Sale',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'The deed of sale helps verify ownership and speeds up the transaction process.',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
