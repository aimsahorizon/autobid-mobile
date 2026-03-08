import 'dart:async';
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
  final _plateLetterFocus = FocusNode();
  final _plateNumberFocus = FocusNode();
  final _validatePlateUseCase = GetIt.I<ValidatePlateNumberUseCase>();

  String? _province;
  String? _city;
  String? _barangay;
  String? _orcrStatus;
  String? _registrationStatus;
  DateTime? _registrationExpiry;

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

    // Initial validation if existing value
    if (_combinedPlate.isNotEmpty) {
      _validatePlate(_combinedPlate);
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
    _plateLetterController.removeListener(_onPlateChanged);
    _plateNumberController.removeListener(_onPlateChanged);
    _plateLetterController.dispose();
    _plateNumberController.dispose();
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
            setState(() => _registrationStatus = v);
            _updateDraft();
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            _unfocusPlateFields();
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _registrationExpiry ??
                  DateTime.now().add(const Duration(days: 365)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
      ],
    );
  }
}
