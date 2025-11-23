import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';

class Step2MechanicalSpec extends StatefulWidget {
  final ListingDraftController controller;

  const Step2MechanicalSpec({super.key, required this.controller});

  @override
  State<Step2MechanicalSpec> createState() => _Step2MechanicalSpecState();
}

class _Step2MechanicalSpecState extends State<Step2MechanicalSpec> {
  late TextEditingController _displacementController;
  late TextEditingController _cylinderController;
  late TextEditingController _horsepowerController;
  late TextEditingController _torqueController;

  String? _engineType;
  String? _transmission;
  String? _fuelType;
  String? _driveType;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _displacementController = TextEditingController(text: draft.engineDisplacement?.toString());
    _cylinderController = TextEditingController(text: draft.cylinderCount?.toString());
    _horsepowerController = TextEditingController(text: draft.horsepower?.toString());
    _torqueController = TextEditingController(text: draft.torque?.toString());
    _engineType = draft.engineType;
    _transmission = draft.transmission;
    _fuelType = draft.fuelType;
    _driveType = draft.driveType;

    _displacementController.addListener(_updateDraft);
    _cylinderController.addListener(_updateDraft);
    _horsepowerController.addListener(_updateDraft);
    _torqueController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _displacementController.dispose();
    _cylinderController.dispose();
    _horsepowerController.dispose();
    _torqueController.dispose();
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
        engineType: _engineType,
        engineDisplacement: _displacementController.text.isEmpty ? null : double.tryParse(_displacementController.text),
        cylinderCount: _cylinderController.text.isEmpty ? null : int.tryParse(_cylinderController.text),
        horsepower: _horsepowerController.text.isEmpty ? null : int.tryParse(_horsepowerController.text),
        torque: _torqueController.text.isEmpty ? null : int.tryParse(_torqueController.text),
        transmission: _transmission,
        fuelType: _fuelType,
        driveType: _driveType,
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
          'Step 2: Mechanical Specification',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormDropdownWidget(
          label: 'Engine Type *',
          value: _engineType,
          items: const ['Inline-4', 'V6', 'V8', 'Flat-4', 'Inline-3', 'Electric'],
          onChanged: (v) {
            setState(() => _engineType = v);
            _updateDraft();
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _displacementController,
          label: 'Engine Displacement (L)',
          hint: 'e.g., 2.0',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _cylinderController,
          label: 'Cylinder Count',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _horsepowerController,
          label: 'Horsepower (HP)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _torqueController,
          label: 'Torque (Nm)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'Transmission *',
          value: _transmission,
          items: const ['Manual', 'Automatic', 'CVT', 'DCT'],
          onChanged: (v) {
            setState(() => _transmission = v);
            _updateDraft();
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'Fuel Type *',
          value: _fuelType,
          items: const ['Gasoline', 'Diesel', 'Electric', 'Hybrid', 'Plug-in Hybrid'],
          onChanged: (v) {
            setState(() => _fuelType = v);
            _updateDraft();
          },
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'Drive Type',
          value: _driveType,
          items: const ['FWD', 'RWD', 'AWD', '4WD'],
          onChanged: (v) {
            setState(() => _driveType = v);
            _updateDraft();
          },
        ),
      ],
    );
  }
}
