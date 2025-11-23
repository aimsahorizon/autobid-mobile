import 'package:flutter/material.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';

class Step8FinalDetails extends StatefulWidget {
  final ListingDraftController controller;

  const Step8FinalDetails({super.key, required this.controller});

  @override
  State<Step8FinalDetails> createState() => _Step8FinalDetailsState();
}

class _Step8FinalDetailsState extends State<Step8FinalDetails> {
  late TextEditingController _descriptionController;
  late TextEditingController _issuesController;
  late TextEditingController _featureController;

  List<String> _features = [];

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _descriptionController = TextEditingController(text: draft.description);
    _issuesController = TextEditingController(text: draft.knownIssues);
    _featureController = TextEditingController();
    _features = draft.features ?? [];

    _descriptionController.addListener(_updateDraft);
    _issuesController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _issuesController.dispose();
    _featureController.dispose();
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
        plateNumber: draft.plateNumber,
        orcrStatus: draft.orcrStatus,
        registrationStatus: draft.registrationStatus,
        registrationExpiry: draft.registrationExpiry,
        province: draft.province,
        cityMunicipality: draft.cityMunicipality,
        photoUrls: draft.photoUrls,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        knownIssues: _issuesController.text.isEmpty ? null : _issuesController.text,
        features: _features.isEmpty ? null : _features,
        startingPrice: draft.startingPrice,
        reservePrice: draft.reservePrice,
        auctionEndDate: draft.auctionEndDate,
      ),
    );
  }

  void _addFeature() {
    if (_featureController.text.trim().isEmpty) return;
    setState(() {
      _features.add(_featureController.text.trim());
      _featureController.clear();
    });
    _updateDraft();
  }

  void _removeFeature(int index) {
    setState(() {
      _features.removeAt(index);
    });
    _updateDraft();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Step 8: Final Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FormFieldWidget(
          controller: _descriptionController,
          label: 'Description *',
          hint: 'Describe your vehicle in detail...',
          maxLines: 5,
          validator: (v) {
            if (v?.isEmpty ?? true) return 'Required';
            if (v!.length < 50) return 'Minimum 50 characters';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${_descriptionController.text.length}/50 characters minimum',
          style: TextStyle(
            fontSize: 12,
            color: _descriptionController.text.length >= 50
                ? Colors.green
                : Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          controller: _issuesController,
          label: 'Known Issues (Optional)',
          hint: 'Disclose any known issues or defects...',
          maxLines: 4,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: FormFieldWidget(
                controller: _featureController,
                label: 'Features',
                hint: 'e.g., Sunroof, Leather Seats',
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addFeature,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        if (_features.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _features.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                onDeleted: () => _removeFeature(entry.key),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
