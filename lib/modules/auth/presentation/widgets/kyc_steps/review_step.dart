import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';

class ReviewStep extends StatelessWidget {
  final KYCRegistrationController controller;
  final Function(KYCStep) onEditStep;

  const ReviewStep({
    super.key,
    required this.controller,
    required this.onEditStep,
  });

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review all your information before submitting',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            context: context,
            title: 'National ID',
            icon: Icons.badge_rounded,
            step: KYCStep.nationalId,
            children: [
              _buildInfoRow('ID Number', controller.nationalIdNumber ?? 'N/A'),
              _buildInfoRow('Front Photo', controller.nationalIdFront != null ? 'Uploaded' : 'Not uploaded'),
              _buildInfoRow('Back Photo', controller.nationalIdBack != null ? 'Uploaded' : 'Not uploaded'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Selfie Verification',
            icon: Icons.face_rounded,
            step: KYCStep.selfieWithId,
            children: [
              _buildInfoRow('Selfie with ID', controller.selfieWithId != null ? 'Uploaded' : 'Not uploaded'),
              _buildInfoRow('AI Auto-fill', controller.aiAutoFillAccepted ? 'Accepted' : 'Skipped'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Secondary ID',
            icon: Icons.credit_card_rounded,
            step: KYCStep.secondaryId,
            children: [
              _buildInfoRow('ID Type', controller.secondaryIdType ?? 'N/A'),
              _buildInfoRow('ID Number', controller.secondaryIdNumber ?? 'N/A'),
              _buildInfoRow('Front Photo', controller.secondaryIdFront != null ? 'Uploaded' : 'Not uploaded'),
              _buildInfoRow('Back Photo', controller.secondaryIdBack != null ? 'Uploaded' : 'Not uploaded'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Personal Information',
            icon: Icons.person_rounded,
            step: KYCStep.personalInfo,
            children: [
              _buildInfoRow('Name', '${controller.firstName ?? ''} ${controller.middleName ?? ''} ${controller.lastName ?? ''}'.trim()),
              _buildInfoRow('Date of Birth', controller.dateOfBirth != null ? _formatDate(controller.dateOfBirth!) : 'N/A'),
              _buildInfoRow('Sex', controller.sex ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Account Information',
            icon: Icons.account_circle_rounded,
            step: KYCStep.accountInfo,
            children: [
              _buildInfoRow('Email', controller.email ?? 'N/A'),
              _buildInfoRow('Phone', '+63${controller.phoneNumber ?? ''}'),
              _buildInfoRow('Terms & Conditions', controller.termsAccepted ? 'Accepted' : 'Not accepted'),
              _buildInfoRow('Privacy Policy', controller.privacyAccepted ? 'Accepted' : 'Not accepted'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Verification Status',
            icon: Icons.verified_user_rounded,
            step: KYCStep.otpVerification,
            children: [
              _buildInfoRow('Phone Verified', controller.phoneOtpVerified ? 'Yes' : 'No',
                verified: controller.phoneOtpVerified),
              _buildInfoRow('Email Verified', controller.emailOtpVerified ? 'Yes' : 'No',
                verified: controller.emailOtpVerified),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Address',
            icon: Icons.location_on_rounded,
            step: KYCStep.address,
            children: [
              _buildInfoRow('Region', controller.region ?? 'N/A'),
              _buildInfoRow('Province', controller.province ?? 'N/A'),
              _buildInfoRow('City', controller.city ?? 'N/A'),
              _buildInfoRow('Barangay', controller.barangay ?? 'N/A'),
              _buildInfoRow('Street', controller.street ?? 'N/A'),
              _buildInfoRow('ZIP Code', controller.zipCode ?? 'N/A'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context: context,
            title: 'Proof of Address',
            icon: Icons.description_rounded,
            step: KYCStep.proofOfAddress,
            children: [
              _buildInfoRow('Document', controller.proofOfAddress != null ? 'Uploaded' : 'Not uploaded'),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: ColorConstants.success,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By submitting this registration, you confirm that all information provided is accurate and true',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required KYCStep step,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: ColorConstants.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => onEditStep(step),
                tooltip: 'Edit',
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool verified = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: ColorConstants.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (verified)
                  const Icon(
                    Icons.check_circle,
                    color: ColorConstants.success,
                    size: 16,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
