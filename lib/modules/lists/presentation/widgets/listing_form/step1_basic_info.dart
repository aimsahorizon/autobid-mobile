import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
// ...existing code...
import '../../controllers/listing_draft_controller.dart';
import 'form_field_widget.dart';
import 'combo_box_widget.dart';
import 'package:autobid_mobile/core/services/car_api_service.dart';

class Step1BasicInfo extends StatefulWidget {
  final ListingDraftController controller;

  const Step1BasicInfo({super.key, required this.controller});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _yearController;
  late TextEditingController _searchController;
  Timer? _searchDebounce;

  String? _brand;
  String? _model;
  String? _variant;
  String? _bodyType;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _brand = draft.brand;
    _model = draft.model;
    _variant = draft.variant;
    _bodyType = draft.bodyType;
    _yearController = TextEditingController(text: draft.year?.toString());
    _yearController.addListener(_updateDraft);
    _searchController = TextEditingController();
    widget.controller.addListener(_onControllerChanged);

    // Initial load
    widget.controller.loadBrands().then((_) {
      if (_brand != null && mounted) {
        widget.controller.loadModels(_brand!).then((_) {
          if (_model != null && mounted) {
            widget.controller.loadVariants(_model!);
          }
        });
      }
    });
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final draft = widget.controller.currentDraft;
    if (draft == null) return;

    final brandChanged = _brand != draft.brand;
    final modelChanged = _model != draft.model;

    // Sync local state from draft (for demo autofill)
    _brand = draft.brand;
    _model = draft.model;
    _variant = draft.variant;
    _bodyType = draft.bodyType;
    final yearText = draft.year?.toString() ?? '';
    if (_yearController.text != yearText) {
      _yearController.removeListener(_updateDraft);
      _yearController.text = yearText;
      _yearController.addListener(_updateDraft);
    }

    // Always rebuild — controller also exposes loading flags and item lists
    setState(() {});

    // Load dependent data when parent fields changed externally
    if (brandChanged && _brand != null) {
      widget.controller.loadModels(_brand!).then((_) {
        if (modelChanged && _model != null && mounted) {
          widget.controller.loadVariants(_model!);
        }
      });
    } else if (modelChanged && _model != null) {
      widget.controller.loadVariants(_model!);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _yearController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateDraft() {
    final draft = widget.controller.currentDraft!;
    widget.controller.updateDraft(
      draft.copyWith(
        lastSaved: DateTime.now(),
        brand: _brand,
        model: _model,
        variant: _variant,
        bodyType: _bodyType,
        year: _yearController.text.isEmpty
            ? null
            : int.tryParse(_yearController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Step 2: Basic Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the basic details of your vehicle',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Car Search Autofill
          _buildCarSearchField(),
          const SizedBox(height: 16),

          if (widget.controller.isLoadingVehicleData &&
              widget.controller.brands.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            ),

          ComboBoxWidget(
            label: 'Brand *',
            value: _brand,
            items: widget.controller.brands.map((e) => e.name).toList(),
            hint: 'Select Brand',
            onChanged: (v) {
              setState(() {
                _brand = v;
                _model = null;
                _variant = null;
              });
              _updateDraft();
              if (v != null &&
                  widget.controller.brands.any((b) => b.name == v)) {
                widget.controller.loadModels(v);
              }
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ComboBoxWidget(
            label: 'Model *',
            value: _model,
            items: widget.controller.models.map((e) => e.name).toList(),
            hint: 'Select Model',
            onChanged: (v) {
              setState(() {
                _model = v;
                _variant = null;
              });
              _updateDraft();
              if (v != null &&
                  widget.controller.models.any((m) => m.name == v)) {
                widget.controller.loadVariants(v);
              }
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            enabled: _brand != null,
          ),
          const SizedBox(height: 16),
          ComboBoxWidget(
            label: 'Variant *',
            value: _variant,
            items: widget.controller.variants.map((e) => e.name).toList(),
            hint: 'Select Variant',
            onChanged: (v) {
              setState(() => _variant = v);
              _updateDraft();
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            enabled: _model != null,
          ),
          const SizedBox(height: 16),
          ComboBoxWidget(
            label: 'Body Type',
            value: _bodyType,
            items: const [
              'Sedan',
              'SUV',
              'Hatchback',
              'Pickup',
              'MPV',
              'Van',
              'Crossover',
              'Coupe',
              'Convertible',
              'Wagon',
            ],
            hint: 'Select Body Type',
            onChanged: (v) {
              setState(() => _bodyType = v);
              _updateDraft();
            },
          ),
          const SizedBox(height: 16),
          FormFieldWidget(
            controller: _yearController,
            label: 'Year *',
            hint: 'e.g., 2020',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (v) {
              if (v?.isEmpty ?? true) return 'Required';
              final year = int.tryParse(v!);
              if (year == null) return 'Invalid year';
              if (year < 1900 || year > DateTime.now().year + 1) {
                return 'Invalid year range';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Quick Search',
            hintText: 'e.g. Toyota Vios 1.5 G',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.isSearchingCars
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      widget.controller.clearCarSearch();
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 400), () {
              widget.controller.searchCars(value);
            });
          },
        ),
        if (widget.controller.carSearchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.controller.carSearchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = widget.controller.carSearchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    result.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    [
                      if (result.bodyType != null) result.bodyType,
                      if (result.transmission != null) result.transmission,
                      if (result.fuelType != null) result.fuelType,
                    ].join(' · '),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  onTap: () async {
                    _searchController.clear();
                    await widget.controller.applyCarSearchResult(result);
                    // Local state will sync via _onControllerChanged
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
