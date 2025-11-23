import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/listing_draft_controller.dart';
import '../../../domain/entities/listing_draft_entity.dart';
import 'form_field_widget.dart';

class Step9Summary extends StatefulWidget {
  final ListingDraftController controller;
  final VoidCallback onSubmitSuccess;

  const Step9Summary({
    super.key,
    required this.controller,
    required this.onSubmitSuccess,
  });

  @override
  State<Step9Summary> createState() => _Step9SummaryState();
}

class _Step9SummaryState extends State<Step9Summary> {
  late TextEditingController _startingPriceController;
  late TextEditingController _reservePriceController;
  DateTime? _auctionEndDate;

  @override
  void initState() {
    super.initState();
    final draft = widget.controller.currentDraft!;
    _startingPriceController = TextEditingController(text: draft.startingPrice?.toString());
    _reservePriceController = TextEditingController(text: draft.reservePrice?.toString());
    _auctionEndDate = draft.auctionEndDate;

    _startingPriceController.addListener(_updateDraft);
    _reservePriceController.addListener(_updateDraft);
  }

  @override
  void dispose() {
    _startingPriceController.dispose();
    _reservePriceController.dispose();
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
        description: draft.description,
        knownIssues: draft.knownIssues,
        features: draft.features,
        startingPrice: _startingPriceController.text.isEmpty ? null : double.tryParse(_startingPriceController.text),
        reservePrice: _reservePriceController.text.isEmpty ? null : double.tryParse(_reservePriceController.text),
        auctionEndDate: _auctionEndDate,
      ),
    );
  }

  Future<void> _submitListing() async {
    final success = await widget.controller.submitListing();
    if (success) {
      widget.onSubmitSuccess();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final draft = widget.controller.currentDraft!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Step 9: Review & Submit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Pricing section
            FormFieldWidget(
              controller: _startingPriceController,
              label: 'Starting Price (₱) *',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            FormFieldWidget(
              controller: _reservePriceController,
              label: 'Reserve Price (₱)',
              hint: 'Optional minimum acceptable price',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _auctionEndDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _auctionEndDate = picked);
                  _updateDraft();
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Auction End Date *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_auctionEndDate != null
                        ? '${_auctionEndDate!.month}/${_auctionEndDate!.day}/${_auctionEndDate!.year}'
                        : 'Select date'),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'Completion Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorConstants.textPrimaryDark
                    : ColorConstants.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: draft.completionPercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${draft.completionPercentage.toStringAsFixed(0)}% Complete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: draft.completionPercentage >= 100
                    ? Colors.green
                    : ColorConstants.primary,
              ),
            ),

            const SizedBox(height: 24),
            ...List.generate(9, (index) {
              final step = index + 1;
              final isComplete = draft.isStepComplete(step);
              return _buildStepSummary(step, isComplete, isDark);
            }),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.controller.isSubmitting || !draft.isComplete
                  ? null
                  : _submitListing,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.controller.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Listing',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepSummary(int step, bool isComplete, bool isDark) {
    final stepTitles = [
      'Basic Information',
      'Mechanical Specification',
      'Dimensions & Capacity',
      'Exterior Details',
      'Condition & History',
      'Documentation & Location',
      'Photos',
      'Final Details',
      'Pricing',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Step $step: ${stepTitles[step - 1]}',
              style: TextStyle(
                fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (!isComplete)
            TextButton(
              onPressed: () => widget.controller.goToStep(step),
              child: const Text('Edit'),
            ),
        ],
      ),
    );
  }
}
