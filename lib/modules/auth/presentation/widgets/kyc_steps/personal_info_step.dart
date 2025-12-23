import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';

class PersonalInfoStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const PersonalInfoStep({
    super.key,
    required this.controller,
  });

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller.firstName != null) {
      _firstNameController.text = widget.controller.firstName!;
    }
    if (widget.controller.middleName != null) {
      _middleNameController.text = widget.controller.middleName!;
    }
    if (widget.controller.lastName != null) {
      _lastNameController.text = widget.controller.lastName!;
    }

    _firstNameController.addListener(() {
      widget.controller.setFirstName(_firstNameController.text);
    });
    _middleNameController.addListener(() {
      widget.controller.setMiddleName(_middleNameController.text);
    });
    _lastNameController.addListener(() {
      widget.controller.setLastName(_lastNameController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final initialDate = widget.controller.dateOfBirth ?? DateTime(now.year - 25);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 18);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select Date of Birth',
    );

    if (pickedDate != null) {
      widget.controller.setDateOfBirth(pickedDate);
      setState(() {});
    }
  }

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
            'Personal Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your personal information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          if (widget.controller.aiAutoFillAccepted)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: ColorConstants.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ColorConstants.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: ColorConstants.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Information auto-filled from your ID. Please review and edit if needed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorConstants.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'First Name',
              hintText: 'Enter your first name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _middleNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Middle Name',
              hintText: 'Enter your middle name (optional)',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              hintText: 'Enter your last name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                hintText: 'Select your date of birth',
                prefixIcon: Icon(Icons.calendar_today_rounded),
                suffixIcon: Icon(Icons.arrow_drop_down_rounded),
              ),
              child: Text(
                widget.controller.dateOfBirth != null
                    ? _formatDate(widget.controller.dateOfBirth!)
                    : '',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: widget.controller.sex,
            decoration: const InputDecoration(
              labelText: 'Sex',
              hintText: 'Select your sex',
              prefixIcon: Icon(Icons.wc_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (value) {
              if (value != null) {
                widget.controller.setSex(value);
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorConstants.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure your information matches your ID exactly',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.info,
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
}
