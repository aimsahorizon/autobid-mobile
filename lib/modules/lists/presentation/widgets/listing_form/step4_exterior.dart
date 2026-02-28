import 'package:flutter/material.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';
import 'combo_box_widget.dart';

class Step4Exterior extends StatefulWidget {
  final ListingDraftController controller;

  const Step4Exterior({super.key, required this.controller});

  @override
  State<Step4Exterior> createState() => _Step4ExteriorState();
}

class _Step4ExteriorState extends State<Step4Exterior> {
  late TextEditingController _colorController;
  late TextEditingController _rimSizeController;
  late TextEditingController _tireSizeController;
  late TextEditingController _tireBrandController;

  String? _paintType;
  String? _rimType;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _colorController = TextEditingController(text: draft.exteriorColor);
    _rimSizeController = TextEditingController(text: draft.rimSize);
    _tireSizeController = TextEditingController(text: draft.tireSize);
    _tireBrandController = TextEditingController(text: draft.tireBrand);
    _paintType = draft.paintType;
    _rimType = draft.rimType;

    _colorController.addListener(_updateDraft);
    _rimSizeController.addListener(_updateDraft);
    _tireSizeController.addListener(_updateDraft);
    _tireBrandController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _colorController.dispose();
    _rimSizeController.dispose();
    _tireSizeController.dispose();
    _tireBrandController.dispose();
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
        exteriorColor: _colorController.text.isEmpty ? null : _colorController.text,
        paintType: _paintType,
        rimType: _rimType,
        rimSize: _rimSizeController.text.isEmpty ? null : _rimSizeController.text,
        tireSize: _tireSizeController.text.isEmpty ? null : _tireSizeController.text,
        tireBrand: _tireBrandController.text.isEmpty ? null : _tireBrandController.text,
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 4: Exterior Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _colorController,
          label: 'Exterior Color *',
          hint: 'e.g., White, Black, Red',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        ComboBoxWidget(
          label: 'Paint Type *',
          value: _paintType,
          items: const ['Solid', 'Metallic', 'Pearl', 'Matte'],
          onChanged: (v) {
            setState(() => _paintType = v);
            _updateDraft();
          },
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        ComboBoxWidget(
          label: 'Rim Type',
          value: _rimType,
          items: const ['Alloy', 'Steel', 'Chrome', 'Forged'],
          onChanged: (v) {
            setState(() => _rimType = v);
            _updateDraft();
          },
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _rimSizeController,
          label: 'Rim Size',
          hint: 'e.g., 16", 17"',
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _tireSizeController,
          label: 'Tire Size',
          hint: 'e.g., 205/55 R16',
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _tireBrandController,
          label: 'Tire Brand',
          hint: 'e.g., Michelin, Bridgestone',
        ),
      ],
    );
  }
}
