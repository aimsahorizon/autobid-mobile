import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/listing_draft_controller.dart';
import '../widgets/listing_form/step1_basic_info.dart';
import '../widgets/listing_form/step2_mechanical_spec.dart';
import '../widgets/listing_form/step3_dimensions.dart';
import '../widgets/listing_form/step4_exterior.dart';
import '../widgets/listing_form/step5_condition.dart';
import '../widgets/listing_form/step6_documentation.dart';
import '../widgets/listing_form/step7_photos.dart';
import '../widgets/listing_form/step8_final_details.dart';
import '../widgets/listing_form/step9_summary.dart';
import '../widgets/listing_form/listing_success_modal.dart';

class CreateListingPage extends StatefulWidget {
  final ListingDraftController controller;
  final String sellerId;
  final String? draftId;

  const CreateListingPage({
    super.key,
    required this.controller,
    required this.sellerId,
    this.draftId,
  });

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  @override
  void initState() {
    super.initState();
    _initializeDraft();
  }

  Future<void> _initializeDraft() async {
    if (widget.draftId != null) {
      // Load existing draft for editing
      await widget.controller.loadDraft(widget.draftId!);
    } else {
      // Create new draft for new listing
      await widget.controller.createNewDraft(widget.sellerId);
    }
  }

  Future<bool> _onWillPop() async {
    if (widget.controller.currentDraft == null) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Draft?'),
        content: const Text(
          'Do you want to save your progress before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () async {
              await widget.controller.saveDraft();
              if (mounted) Navigator.pop(context, true);
            },
            child: const Text('Save & Exit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListingSuccessModal(
        onCreateAnother: () {
          Navigator.pop(context); // Close modal
          widget.controller.createNewDraft(widget.sellerId);
        },
        onViewListing: () {
          Navigator.pop(context); // Close modal
          // Return with 'pending' to navigate to Pending tab
          Navigator.pop(context, {'success': true, 'navigateTo': 'pending'});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Listing'),
          actions: [
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                if (widget.controller.isSaving) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  onPressed: widget.controller.saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Save Draft',
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            if (widget.controller.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing listing...'),
                  ],
                ),
              );
            }

            final draft = widget.controller.currentDraft;
            if (draft == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      widget.controller.errorMessage ?? 'Failed to initialize listing',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _initializeDraft();
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                _buildStepIndicator(isDark),
                Expanded(
                  child: _buildStepContent(),
                ),
                _buildNavigationBar(isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? ColorConstants.surfaceLight
                : ColorConstants.backgroundSecondaryLight,
          ),
        ),
      ),
      child: Row(
        children: List.generate(9, (index) {
          final step = index + 1;
          // Step 9 should not show as complete unless all previous steps are done
          final isCompleted = step == 9
              ? widget.controller.currentDraft!.completionPercentage >= 100
              : widget.controller.currentDraft!.isStepComplete(step);
          final isCurrent = step == widget.controller.currentStep;

          return Expanded(
            child: GestureDetector(
              onTap: () => widget.controller.goToStep(step),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : (isCurrent
                              ? ColorConstants.primary
                              : (isDark
                                  ? ColorConstants.surfaceLight
                                  : ColorConstants.backgroundSecondaryLight)),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '$step',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark
                                        ? ColorConstants.textSecondaryDark
                                        : ColorConstants.textSecondaryLight),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCurrent)
                    Container(
                      width: 24,
                      height: 3,
                      decoration: BoxDecoration(
                        color: ColorConstants.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (widget.controller.currentStep) {
      case 1:
        // NEW ORDER: Photos first with AI detection
        return Step7Photos(controller: widget.controller);
      case 2:
        // AI-prefilled from photos
        return Step1BasicInfo(controller: widget.controller);
      case 3:
        return Step2MechanicalSpec(controller: widget.controller);
      case 4:
        return Step3Dimensions(controller: widget.controller);
      case 5:
        return Step4Exterior(controller: widget.controller);
      case 6:
        return Step5Condition(controller: widget.controller);
      case 7:
        return Step6Documentation(controller: widget.controller);
      case 8:
        return Step8FinalDetails(controller: widget.controller);
      case 9:
        return Step9Summary(
          controller: widget.controller,
          onSubmitSuccess: _showSuccessModal,
        );
      default:
        return const Center(child: Text('Invalid step'));
    }
  }

  Widget _buildNavigationBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? ColorConstants.surfaceLight
                : ColorConstants.backgroundSecondaryLight,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.controller.canGoPrevious)
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.controller.goToPreviousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (widget.controller.canGoPrevious && widget.controller.canGoNext)
              const SizedBox(width: 12),
            if (widget.controller.canGoNext)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.controller.goToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Next'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
