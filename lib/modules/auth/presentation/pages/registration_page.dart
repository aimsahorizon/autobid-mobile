import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/kyc_registration_controller.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = KYCRegistrationController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getStepTitle() {
    switch (_controller.currentStep) {
      case KYCStep.nationalId:
        return 'National ID';
      case KYCStep.selfieWithId:
        return 'Selfie Verification';
      case KYCStep.secondaryId:
        return 'Secondary ID';
      case KYCStep.personalInfo:
        return 'Personal Info';
      case KYCStep.accountInfo:
        return 'Account Setup';
      case KYCStep.otpVerification:
        return 'Verification';
      case KYCStep.address:
        return 'Address';
      case KYCStep.proofOfAddress:
        return 'Proof of Address';
      case KYCStep.review:
        return 'Review';
    }
  }

  bool _canProceed() {
    switch (_controller.currentStep) {
      case KYCStep.nationalId:
        return _controller.validateNationalIdStep();
      case KYCStep.selfieWithId:
        return _controller.validateSelfieStep();
      case KYCStep.secondaryId:
        return _controller.validateSecondaryIdStep();
      case KYCStep.personalInfo:
        return _controller.validatePersonalInfoStep();
      case KYCStep.accountInfo:
        return _controller.validateAccountInfoStep();
      case KYCStep.otpVerification:
        return _controller.validateOtpStep();
      case KYCStep.address:
        return _controller.validateAddressStep();
      case KYCStep.proofOfAddress:
        return _controller.validateProofOfAddressStep();
      case KYCStep.review:
        return true;
    }
  }

  void _handleNext() {
    if (_canProceed()) {
      if (_controller.currentStep == KYCStep.review) {
        _handleSubmit();
      } else {
        _controller.nextStep();
        setState(() {});
      }
    }
  }

  void _handleBack() {
    if (_controller.currentStepIndex > 0) {
      _controller.previousStep();
      setState(() {});
    } else {
      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _handleBack,
        ),
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
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_controller.currentStepIndex + 1) / _controller.totalSteps;

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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(ColorConstants.primary),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_controller.currentStep) {
      case KYCStep.nationalId:
        return NationalIdStep(controller: _controller);
      case KYCStep.selfieWithId:
        return SelfieWithIdStep(
          controller: _controller,
          onAIAutoFillComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Information auto-filled successfully!'),
                backgroundColor: ColorConstants.success,
              ),
            );
          },
        );
      case KYCStep.secondaryId:
        return SecondaryIdStep(controller: _controller);
      case KYCStep.personalInfo:
        return PersonalInfoStep(controller: _controller);
      case KYCStep.accountInfo:
        return AccountInfoStep(controller: _controller);
      case KYCStep.otpVerification:
        return OtpVerificationStep(controller: _controller);
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
      child: Row(
        children: [
          if (_controller.currentStepIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _handleBack,
                child: const Text('Back'),
              ),
            ),
          if (_controller.currentStepIndex > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _handleNext,
              child: Text(
                _controller.currentStep == KYCStep.review ? 'Submit' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
