import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ...existing code...
import '../../controllers/listing_draft_controller.dart';
import 'form_field_widget.dart';
import 'combo_box_widget.dart';

class Step1BasicInfo extends StatefulWidget {
  final ListingDraftController controller;

  const Step1BasicInfo({super.key, required this.controller});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _yearController;

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
    widget.controller.removeListener(_onControllerChanged);
    _yearController.dispose();
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
}
