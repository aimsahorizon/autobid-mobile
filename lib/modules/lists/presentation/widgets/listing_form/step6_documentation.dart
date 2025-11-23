import 'package:flutter/material.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';

class Step6Documentation extends StatefulWidget {
  final ListingDraftController controller;

  const Step6Documentation({super.key, required this.controller});

  @override
  State<Step6Documentation> createState() => _Step6DocumentationState();
}

class _Step6DocumentationState extends State<Step6Documentation> {
  late TextEditingController _plateController;
  late TextEditingController _provinceController;
  late TextEditingController _cityController;

  String? _orcrStatus;
  String? _registrationStatus;
  DateTime? _registrationExpiry;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _plateController = TextEditingController(text: draft.plateNumber);
    _provinceController = TextEditingController(text: draft.province);
    _cityController = TextEditingController(text: draft.cityMunicipality);
    _orcrStatus = draft.orcrStatus;
    _registrationStatus = draft.registrationStatus;
    _registrationExpiry = draft.registrationExpiry;

    _plateController.addListener(_updateDraft);
    _provinceController.addListener(_updateDraft);
    _cityController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
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
        condition: draft.condition,
        mileage: draft.mileage,
        previousOwners: draft.previousOwners,
        hasModifications: draft.hasModifications,
        modificationsDetails: draft.modificationsDetails,
        hasWarranty: draft.hasWarranty,
        warrantyDetails: draft.warrantyDetails,
        usageType: draft.usageType,
        plateNumber: _plateController.text.isEmpty ? null : _plateController.text,
        orcrStatus: _orcrStatus,
        registrationStatus: _registrationStatus,
        registrationExpiry: _registrationExpiry,
        province: _provinceController.text.isEmpty ? null : _provinceController.text,
        cityMunicipality: _cityController.text.isEmpty ? null : _cityController.text,
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
          'Step 6: Documentation & Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _plateController,
          label: 'Plate Number *',
          hint: 'e.g., ABC 1234',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormDropdownWidget(
          label: 'OR/CR Status *',
          value: _orcrStatus,
          items: const ['Available', 'In Process', 'Lost', 'Not Available'],
          onChanged: (v) {
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
            setState(() => _registrationStatus = v);
            _updateDraft();
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _registrationExpiry ?? DateTime.now().add(const Duration(days: 365)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_registrationExpiry != null
                    ? '${_registrationExpiry!.month}/${_registrationExpiry!.day}/${_registrationExpiry!.year}'
                    : 'Select date'),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _provinceController,
          label: 'Province *',
          hint: 'e.g., Metro Manila, Cebu',
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _cityController,
          label: 'City/Municipality',
          hint: 'e.g., Quezon City, Makati',
        ),
      ],
    );
  }
}
