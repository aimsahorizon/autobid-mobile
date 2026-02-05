import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/app/di/app_module.dart';
import '../controllers/kyc_registration_controller.dart';
import '../../auth_routes.dart';
import '../widgets/kyc_steps/national_id_step.dart';
import '../widgets/kyc_steps/selfie_with_id_step.dart';
import '../widgets/kyc_steps/secondary_id_step.dart';
import '../widgets/kyc_steps/personal_info_step.dart';
import '../widgets/kyc_steps/account_info_step.dart';
import '../widgets/kyc_steps/otp_verification_step.dart';
import '../widgets/kyc_steps/address_step.dart';
import '../widgets/kyc_steps/proof_of_address_step.dart';
import '../widgets/kyc_steps/review_step.dart';
import '../widgets/auth_error_message.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late final KYCRegistrationController _controller;
  final GlobalKey<SecondaryIdStepState> _secondaryIdKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Use GetIt to create controller
    _controller = sl<KYCRegistrationController>();

    // Check for saved draft
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDraft();
    });
  }

  Future<void> _checkForDraft() async {
    final hasDraft = await _controller.hasSavedDraft();
    if (!hasDraft || !mounted) return;

    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Registration?'),
        content: const Text(
          'We found a saved draft of your registration. Would you like to continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Start Fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (resume == true) {
      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await _controller.loadDraft();

      if (mounted) {
        Navigator.pop(context); // Remove loading
        setState(() {}); // Refresh UI
      }
    } else {
      _controller.clearAllData(); // Clear draft if starting fresh
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStepTitle() {
    switch (_controller.currentStep) {
      case KYCStep.accountInfo:
        return 'Account Setup';
      case KYCStep.otpVerification:
        return 'Verification';
      case KYCStep.nationalId:
        return 'National ID';
      case KYCStep.selfieWithId:
        return 'Selfie Verification';
      case KYCStep.secondaryId:
        return 'Secondary ID';
      case KYCStep.personalInfo:
        return 'Personal Info';
      case KYCStep.address:
        return 'Address';
      case KYCStep.proofOfAddress:
        return 'Proof of Address';
      case KYCStep.review:
        return 'Review';
    }
  }

  void _handleNext() {
    // Validation is already checked via isCurrentStepValid for button state
    // But we trigger one last check with error reporting enabled to show any hidden errors if needed
    // or just proceed.
    // Since button is disabled if invalid, we can assume it's valid here.
    // However, some async checks (like secondary ID AI) might need explicit trigger.

    // Trigger AI extraction for secondary ID step before proceeding
    if (_controller.currentStep == KYCStep.secondaryId) {
      _secondaryIdKey.currentState?.triggerAiExtraction();
      return; // AI dialog will handle next step
    }

    if (_controller.currentStep == KYCStep.review) {
      _handleSubmit();
    } else {
      _controller.nextStep();
      setState(() {});
    }
  }

  // Called by SecondaryIdStep after AI extraction completes
  void _proceedToNextStep() {
    _controller.nextStep();
    setState(() {});
  }

  void _handlePreviousStep() {
    if (_controller.currentStepIndex > 0) {
      _controller.previousStep();
      setState(() {});
    }
  }

  void _handleExit() {
    _showExitConfirmationDialog();
  }

  Future<void> _showExitConfirmationDialog() async {
    // Check if user has entered any data
    final hasData = _controller.hasAnyDataEntered();

    if (!hasData) {
      // No data entered, just go back to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
      }
      return;
    }

    // Show dialog asking to save or discard
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Your Progress?'),
        content: const Text(
          'You have entered some registration information. Would you like to save it for later or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save Draft'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == 'save') {
      // Save draft and show confirmation
      await _controller.saveDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration progress saved. You can continue later.',
            ),
            backgroundColor: ColorConstants.success,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
      }
    } else if (result == 'discard') {
      // Clear data and go back
      _controller.clearAllData();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AuthRoutes.login);
      }
    }
  }

  Future<void> _handleSubmit() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting your registration...'),
              ],
            ),
          ),
        ),
      ),
    );

    await _controller.submitRegistration();

    if (mounted) {
      Navigator.of(context).pop();

      if (_controller.errorMessage == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: ColorConstants.success),
                SizedBox(width: 12),
                Text('Success!'),
              ],
            ),
            content: const Text(
              'Your registration has been submitted successfully. We will review your application and notify you once it\'s approved.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getStepTitle()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleExit,
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.auto_awesome,
                color: ColorConstants.warning,
              ),
              tooltip: 'Auto-fill Demo Data',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: ColorConstants.warning),
                        SizedBox(width: 12),
                        Text('Auto-fill Demo Data'),
                      ],
                    ),
                    content: const Text(
                      'This will automatically fill all fields with randomized demo data.\n\nNote: Email and document uploads must still be filled manually.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _controller.autoFillDemoData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Demo data auto-filled successfully!',
                              ),
                              backgroundColor: ColorConstants.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Auto-fill'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (_controller.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: AuthErrorMessage(
                              message: _controller.errorMessage!,
                              onDismiss: _controller.clearError,
                            ),
                          ),
                        _buildCurrentStep(),
                      ],
                    ),
                  ),
                ),
                _buildNavigationButtons(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress =
        (_controller.currentStepIndex + 1) / _controller.totalSteps;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_controller.currentStepIndex + 1} of ${_controller.totalSteps}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(
            ColorConstants.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_controller.currentStep) {
      case KYCStep.accountInfo:
        return AccountInfoStep(controller: _controller);
      case KYCStep.otpVerification:
        return OtpVerificationStep(controller: _controller);
      case KYCStep.nationalId:
        return NationalIdStep(controller: _controller);
      case KYCStep.selfieWithId:
        return SelfieWithIdStep(controller: _controller);
      case KYCStep.secondaryId:
        return SecondaryIdStep(
          key: _secondaryIdKey,
          controller: _controller,
          onRequestAiExtraction: _proceedToNextStep,
        );
      case KYCStep.personalInfo:
        return PersonalInfoStep(controller: _controller);
      case KYCStep.address:
        return AddressStep(controller: _controller);
      case KYCStep.proofOfAddress:
        return ProofOfAddressStep(controller: _controller);
      case KYCStep.review:
        return ReviewStep(
          controller: _controller,
          onEditStep: (step) {
            _controller.goToStep(step);
            setState(() {});
          },
        );
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_controller.currentStepIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handlePreviousStep,
                    child: const Text('Back'),
                  ),
                ),
              if (_controller.currentStepIndex > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _controller.isCurrentStepValid
                      ? _handleNext
                      : null,
                  child: Text(
                    _controller.currentStep == KYCStep.review
                        ? 'Submit'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
          if (_controller.currentStepIndex == 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushReplacementNamed(AuthRoutes.login);
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: ColorConstants.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
