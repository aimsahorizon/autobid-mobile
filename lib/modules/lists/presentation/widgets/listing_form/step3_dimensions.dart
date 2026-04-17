import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/utils/thousands_separator_formatter.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';

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
    _lengthController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.length),
    );
    _widthController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.width),
    );
    _heightController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.height),
    );
    _wheelbaseController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.wheelbase),
    );
    _clearanceController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(
        draft.groundClearance,
      ),
    );
    _seatingController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatInt(draft.seatingCapacity),
    );
    _doorController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatInt(draft.doorCount),
    );
    _fuelTankController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(
        draft.fuelTankCapacity,
      ),
    );
    _curbWeightController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.curbWeight),
    );
    _grossWeightController = TextEditingController(
      text: ThousandsSeparatorInputFormatter.formatDouble(draft.grossWeight),
    );

    for (var controller in [
      _lengthController,
      _widthController,
      _heightController,
      _wheelbaseController,
      _clearanceController,
      _seatingController,
      _doorController,
      _fuelTankController,
      _curbWeightController,
      _grossWeightController,
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
        length: ThousandsSeparatorInputFormatter.parseDouble(
          _lengthController.text,
        ),
        width: ThousandsSeparatorInputFormatter.parseDouble(
          _widthController.text,
        ),
        height: ThousandsSeparatorInputFormatter.parseDouble(
          _heightController.text,
        ),
        wheelbase: ThousandsSeparatorInputFormatter.parseDouble(
          _wheelbaseController.text,
        ),
        groundClearance: ThousandsSeparatorInputFormatter.parseDouble(
          _clearanceController.text,
        ),
        seatingCapacity: ThousandsSeparatorInputFormatter.parseInt(
          _seatingController.text,
        ),
        doorCount: ThousandsSeparatorInputFormatter.parseInt(
          _doorController.text,
        ),
        fuelTankCapacity: ThousandsSeparatorInputFormatter.parseDouble(
          _fuelTankController.text,
        ),
        curbWeight: ThousandsSeparatorInputFormatter.parseDouble(
          _curbWeightController.text,
        ),
        grossWeight: ThousandsSeparatorInputFormatter.parseDouble(
          _grossWeightController.text,
        ),
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
          'Step 4: Dimensions & Capacity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _lengthController,
          label: 'Length (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _widthController,
          label: 'Width (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _heightController,
          label: 'Height (mm) *',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _wheelbaseController,
          label: 'Wheelbase (mm)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _clearanceController,
          label: 'Ground Clearance (mm)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _seatingController,
          label: 'Seating Capacity',
          keyboardType: TextInputType.number,
          inputFormatters: [const ThousandsSeparatorInputFormatter()],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _doorController,
          label: 'Door Count',
          keyboardType: TextInputType.number,
          inputFormatters: [const ThousandsSeparatorInputFormatter()],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _fuelTankController,
          label: 'Fuel Tank Capacity (L)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _curbWeightController,
          label: 'Curb Weight (kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _grossWeightController,
          label: 'Gross Weight (kg)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const ThousandsSeparatorInputFormatter(allowDecimal: true),
          ],
        ),
      ],
    );
  }
}
