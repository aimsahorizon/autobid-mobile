import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/modules/lists/domain/entities/listing_draft_entity.dart';
import '../../controllers/listing_draft_controller.dart';
import 'form_field_widget.dart';
import 'combo_box_widget.dart';
import '../../../data/datasources/demo_listing_data.dart';
import 'demo_autofill_button.dart';

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

  static const _brands = [
    'Toyota', 'Honda', 'Ford', 'Mitsubishi', 'Nissan',
    'Hyundai', 'Mazda', 'Suzuki', 'Isuzu', 'Chevrolet',
  ];

  static const _models = [
    'Corolla', 'Civic', 'Mustang', 'Vios', 'City',
    'Fortuner', 'CR-V', 'Ranger', 'Hilux', 'Wigo',
  ];

  static const _variants = [
    'Altis', 'RS', 'GT', 'XLE', 'Base', 'V',
    'Sport', 'Limited', 'Premium', 'Standard',
  ];

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _brand = draft.brand;
    _model = draft.model;
    _variant = draft.variant;
    _yearController = TextEditingController(text: draft.year?.toString());
    _yearController.addListener(_updateDraft);
  }

  @override
  void dispose() {
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
        year: _yearController.text.isEmpty ? null : int.tryParse(_yearController.text),
      ),
    );
  }

  void _autofillDemoData() {
    final demoData = DemoListingData.getDemoDataForStep(1);
    setState(() {
      _brand = demoData['brand'];
      _model = demoData['model'];
      _variant = demoData['variant'];
      _yearController.text = demoData['year'].toString();
    });
    _updateDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Step 1: Basic Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the basic details of your vehicle',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          DemoAutofillButton(onPressed: _autofillDemoData),
          const SizedBox(height: 24),
          ComboBoxWidget(
            label: 'Brand *',
            value: _brand,
            items: _brands,
            hint: 'e.g., Toyota, Honda, Ford',
            onChanged: (v) {
              setState(() => _brand = v);
              _updateDraft();
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ComboBoxWidget(
            label: 'Model *',
            value: _model,
            items: _models,
            hint: 'e.g., Corolla, Civic, Mustang',
            onChanged: (v) {
              setState(() => _model = v);
              _updateDraft();
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ComboBoxWidget(
            label: 'Variant *',
            value: _variant,
            items: _variants,
            hint: 'e.g., Altis, RS, GT',
            onChanged: (v) {
              setState(() => _variant = v);
              _updateDraft();
            },
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
