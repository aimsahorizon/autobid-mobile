import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';
import '../../../data/datasources/demo_listing_data.dart';
import 'demo_autofill_button.dart';

class Step3Dimensions extends StatefulWidget {
  final ListingDraftController controller;

  const Step3Dimensions({super.key, required this.controller});

  @override
  State<Step3Dimensions> createState() => _Step3DimensionsState();
}

class _Step3DimensionsState extends State<Step3Dimensions> {
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _wheelbaseController;
  late TextEditingController _clearanceController;
  late TextEditingController _seatingController;
  late TextEditingController _doorController;
  late TextEditingController _fuelTankController;
  late TextEditingController _curbWeightController;
  late TextEditingController _grossWeightController;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _lengthController = TextEditingController(text: draft.length?.toString());
    _widthController = TextEditingController(text: draft.width?.toString());
    _heightController = TextEditingController(text: draft.height?.toString());
    _wheelbaseController = TextEditingController(text: draft.wheelbase?.toString());
    _clearanceController = TextEditingController(text: draft.groundClearance?.toString());
    _seatingController = TextEditingController(text: draft.seatingCapacity?.toString());
    _doorController = TextEditingController(text: draft.doorCount?.toString());
    _fuelTankController = TextEditingController(text: draft.fuelTankCapacity?.toString());
    _curbWeightController = TextEditingController(text: draft.curbWeight?.toString());
    _grossWeightController = TextEditingController(text: draft.grossWeight?.toString());

    for (var controller in [
      _lengthController, _widthController, _heightController, _wheelbaseController,
      _clearanceController, _seatingController, _doorController, _fuelTankController,
      _curbWeightController, _grossWeightController
    ]) {
      controller.addListener(_updateDraft);
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _wheelbaseController.dispose();
    _clearanceController.dispose();
    _seatingController.dispose();
    _doorController.dispose();
    _fuelTankController.dispose();
    _curbWeightController.dispose();
    _grossWeightController.dispose();
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
        length: _lengthController.text.isEmpty ? null : double.tryParse(_lengthController.text),
        width: _widthController.text.isEmpty ? null : double.tryParse(_widthController.text),
        height: _heightController.text.isEmpty ? null : double.tryParse(_heightController.text),
        wheelbase: _wheelbaseController.text.isEmpty ? null : double.tryParse(_wheelbaseController.text),
        groundClearance: _clearanceController.text.isEmpty ? null : double.tryParse(_clearanceController.text),
        seatingCapacity: _seatingController.text.isEmpty ? null : int.tryParse(_seatingController.text),
        doorCount: _doorController.text.isEmpty ? null : int.tryParse(_doorController.text),
        fuelTankCapacity: _fuelTankController.text.isEmpty ? null : double.tryParse(_fuelTankController.text),
        curbWeight: _curbWeightController.text.isEmpty ? null : double.tryParse(_curbWeightController.text),
        grossWeight: _grossWeightController.text.isEmpty ? null : double.tryParse(_grossWeightController.text),
        exteriorColor: draft.exteriorColor,
        paintType: draft.paintType,
        rimType: draft.rimType,
        rimSize: draft.rimSize,
        tireSize: draft.tireSize,
        tireBrand: draft.tireBrand,
        condition: draft.condition,
        mileage: draft.mileage,
        previousOwners: draft.previousOwners,
        hasModifications: draft.hasModifications,
        modificationsDetails: draft.modificationsDetails,
        hasWarranty: draft.hasWarranty,
        warrantyDetails: draft.warrantyDetails,
        usageType: draft.usageType,
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
    final demoData = DemoListingData.getDemoDataForStep(3);
    setState(() {
      _lengthController.text = demoData['length'].toString();
      _widthController.text = demoData['width'].toString();
      _heightController.text = demoData['height'].toString();
      _wheelbaseController.text = demoData['wheelbase'].toString();
      _clearanceController.text = demoData['groundClearance'].toString();
      _seatingController.text = demoData['seatingCapacity'].toString();
      _doorController.text = demoData['doorCount'].toString();
      _fuelTankController.text = demoData['fuelTankCapacity'].toString();
      _curbWeightController.text = demoData['curbWeight'].toString();
      _grossWeightController.text = demoData['grossWeight'].toString();
    });
    _updateDraft();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 3: Dimensions & Capacity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DemoAutofillButton(onPressed: _autofillDemoData),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _lengthController,
          label: 'Length (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _widthController,
          label: 'Width (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _heightController,
          label: 'Height (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _wheelbaseController,
          label: 'Wheelbase (mm)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _clearanceController,
          label: 'Ground Clearance (mm)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _seatingController,
          label: 'Seating Capacity',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _doorController,
          label: 'Door Count',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _fuelTankController,
          label: 'Fuel Tank Capacity (L)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _curbWeightController,
          label: 'Curb Weight (kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _grossWeightController,
          label: 'Gross Weight (kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
      ],
    );
  }
}
