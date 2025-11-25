import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';
import 'combo_box_widget.dart';
import '../../../data/datasources/demo_listing_data.dart';
import 'demo_autofill_button.dart';

class Step5Condition extends StatefulWidget {
  final ListingDraftController controller;

  const Step5Condition({super.key, required this.controller});

  @override
  State<Step5Condition> createState() => _Step5ConditionState();
}

class _Step5ConditionState extends State<Step5Condition> {
  late TextEditingController _mileageController;
  late TextEditingController _ownersController;
  late TextEditingController _modificationsController;
  late TextEditingController _warrantyController;

  String? _condition;
  bool _hasModifications = false;
  bool _hasWarranty = false;
  String? _usageType;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _mileageController = TextEditingController(text: draft.mileage?.toString());
    _ownersController = TextEditingController(text: draft.previousOwners?.toString());
    _modificationsController = TextEditingController(text: draft.modificationsDetails);
    _warrantyController = TextEditingController(text: draft.warrantyDetails);
    _condition = draft.condition;
    _hasModifications = draft.hasModifications ?? false;
    _hasWarranty = draft.hasWarranty ?? false;
    _usageType = draft.usageType;

    _mileageController.addListener(_updateDraft);
    _ownersController.addListener(_updateDraft);
    _modificationsController.addListener(_updateDraft);
    _warrantyController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _ownersController.dispose();
    _modificationsController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  void _updateDraft() {
    final draft = widget.controller.currentDraft!;
    widget.controller.updateDraft(
      ListingDraftEntity(
        id: draft.id,
        sellerId: draft.sellerId,
        currentStep: draft.currentStep,
        lastSaved: DateTime.now(),
        brand: draft.brand,
        model: draft.model,
        variant: draft.variant,
        year: draft.year,
        engineType: draft.engineType,
        engineDisplacement: draft.engineDisplacement,
        cylinderCount: draft.cylinderCount,
        horsepower: draft.horsepower,
        torque: draft.torque,
        transmission: draft.transmission,
        fuelType: draft.fuelType,
        driveType: draft.driveType,
        length: draft.length,
        width: draft.width,
        height: draft.height,
        wheelbase: draft.wheelbase,
        groundClearance: draft.groundClearance,
        seatingCapacity: draft.seatingCapacity,
        doorCount: draft.doorCount,
        fuelTankCapacity: draft.fuelTankCapacity,
        curbWeight: draft.curbWeight,
        grossWeight: draft.grossWeight,
        exteriorColor: draft.exteriorColor,
        paintType: draft.paintType,
        rimType: draft.rimType,
        rimSize: draft.rimSize,
        tireSize: draft.tireSize,
        tireBrand: draft.tireBrand,
        condition: _condition,
        mileage: _mileageController.text.isEmpty ? null : int.tryParse(_mileageController.text),
        previousOwners: _ownersController.text.isEmpty ? null : int.tryParse(_ownersController.text),
        hasModifications: _hasModifications,
        modificationsDetails: _modificationsController.text.isEmpty ? null : _modificationsController.text,
        hasWarranty: _hasWarranty,
        warrantyDetails: _warrantyController.text.isEmpty ? null : _warrantyController.text,
        usageType: _usageType,
        plateNumber: draft.plateNumber,
        orcrStatus: draft.orcrStatus,
        registrationStatus: draft.registrationStatus,
        registrationExpiry: draft.registrationExpiry,
        province: draft.province,
        cityMunicipality: draft.cityMunicipality,
        photoUrls: draft.photoUrls,
        description: draft.description,
        knownIssues: draft.knownIssues,
        features: draft.features,
        startingPrice: draft.startingPrice,
        reservePrice: draft.reservePrice,
        auctionEndDate: draft.auctionEndDate,
      ),
    );
  }

  void _autofillDemoData() {
    final demoData = DemoListingData.getDemoDataForStep(5);
    setState(() {
      _condition = demoData['condition'];
      _mileageController.text = demoData['mileage'].toString();
      _ownersController.text = demoData['previousOwners'].toString();
      _hasModifications = demoData['hasModifications'];
      _modificationsController.text = demoData['modificationsDetails'] ?? '';
      _hasWarranty = demoData['hasWarranty'];
      _warrantyController.text = demoData['warrantyDetails'] ?? '';
      _usageType = demoData['usageType'];
    });
    _updateDraft();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 5: Condition & History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DemoAutofillButton(onPressed: _autofillDemoData),
        const SizedBox(height: 24),
        ComboBoxWidget(
          label: 'Condition *',
          value: _condition,
          items: const ['Excellent', 'Good', 'Fair', 'Needs Work'],
          onChanged: (v) {
            setState(() => _condition = v);
            _updateDraft();
          },
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _mileageController,
          label: 'Mileage (km) *',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _ownersController,
          label: 'Previous Owners *',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Has Modifications'),
          value: _hasModifications,
          onChanged: (v) {
            setState(() => _hasModifications = v);
            _updateDraft();
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_hasModifications) ...[
          const SizedBox(height: 16),
          FormFieldWidget(
            controller: _modificationsController,
            label: 'Modifications Details',
            maxLines: 3,
          ),
        ],
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Has Warranty'),
          value: _hasWarranty,
          onChanged: (v) {
            setState(() => _hasWarranty = v);
            _updateDraft();
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_hasWarranty) ...[
          const SizedBox(height: 16),
          FormFieldWidget(
            controller: _warrantyController,
            label: 'Warranty Details',
            maxLines: 3,
          ),
        ],
        const SizedBox(height: 16),
        ComboBoxWidget(
          label: 'Usage Type',
          value: _usageType,
          items: const ['Private', 'Commercial', 'Taxi/TNVS'],
          onChanged: (v) {
            setState(() => _usageType = v);
            _updateDraft();
          },
        ),
      ],
    );
  }
}
