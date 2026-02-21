/// Represents a single field in the collaborative transaction agreement form.
/// Both buyer and seller can add/edit/delete fields until they lock.
class AgreementFieldEntity {
  final String id;
  final String transactionId;
  final String label;
  final String value;
  final String fieldType; // text, number, date, boolean, select
  final String category;
  final String? options; // Comma-separated for select type
  final String? addedBy;
  final int displayOrder;

  const AgreementFieldEntity({
    required this.id,
    required this.transactionId,
    required this.label,
    this.value = '',
    this.fieldType = 'text',
    this.category = 'general',
    this.options,
    this.addedBy,
    this.displayOrder = 0,
  });

  AgreementFieldEntity copyWith({
    String? id,
    String? transactionId,
    String? label,
    String? value,
    String? fieldType,
    String? category,
    String? options,
    String? addedBy,
    int? displayOrder,
  }) {
    return AgreementFieldEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      label: label ?? this.label,
      value: value ?? this.value,
      fieldType: fieldType ?? this.fieldType,
      category: category ?? this.category,
      options: options ?? this.options,
      addedBy: addedBy ?? this.addedBy,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  List<String> get selectOptions =>
      options
          ?.split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList() ??
      [];

  bool get boolValue => value.toLowerCase() == 'true';
}

/// Predefined field template for quick-add
class AgreementFieldTemplate {
  final String label;
  final String fieldType;
  final String? options;

  const AgreementFieldTemplate(this.label, this.fieldType, {this.options});
}

/// All predefined agreement field templates grouped by category.
/// Covers every scenario for car auction post-bidding agreements.
class AgreementTemplates {
  static const Map<String, List<AgreementFieldTemplate>> categories = {
    'Vehicle Information': [
      AgreementFieldTemplate('Vehicle Identification Number (VIN)', 'text'),
      AgreementFieldTemplate('Plate Number', 'text'),
      AgreementFieldTemplate('Engine Number', 'text'),
      AgreementFieldTemplate('Chassis Number', 'text'),
      AgreementFieldTemplate('Color', 'text'),
      AgreementFieldTemplate('Current Mileage (km)', 'number'),
      AgreementFieldTemplate('Body Type', 'text'),
      AgreementFieldTemplate(
        'Transmission',
        'select',
        options: 'Manual,Automatic,CVT',
      ),
      AgreementFieldTemplate(
        'Fuel Type',
        'select',
        options: 'Gasoline,Diesel,Hybrid,Electric',
      ),
    ],
    'Payment Terms': [
      AgreementFieldTemplate('Total Agreed Price', 'number'),
      AgreementFieldTemplate('Down Payment / Deposit', 'number'),
      AgreementFieldTemplate('Remaining Balance', 'number'),
      AgreementFieldTemplate(
        'Payment Method',
        'select',
        options: 'Cash,Bank Transfer,GCash,Check,Financing',
      ),
      AgreementFieldTemplate('Bank Name', 'text'),
      AgreementFieldTemplate('Account Holder Name', 'text'),
      AgreementFieldTemplate('Account Number', 'text'),
      AgreementFieldTemplate('Payment Due Date', 'date'),
      AgreementFieldTemplate('Installment Terms', 'text'),
      AgreementFieldTemplate('Proof of Payment Required', 'boolean'),
    ],
    'Document Checklist': [
      AgreementFieldTemplate('OR (Official Receipt) Available', 'boolean'),
      AgreementFieldTemplate(
        'CR (Certificate of Registration) Available',
        'boolean',
      ),
      AgreementFieldTemplate('Deed of Absolute Sale Prepared', 'boolean'),
      AgreementFieldTemplate('Release of Mortgage (if applicable)', 'boolean'),
      AgreementFieldTemplate('Registration Valid Until', 'date'),
      AgreementFieldTemplate('Emission Test Valid', 'boolean'),
      AgreementFieldTemplate('Insurance Transfer Arranged', 'boolean'),
      AgreementFieldTemplate('No Liens / Encumbrances', 'boolean'),
      AgreementFieldTemplate('LTO Transfer Ready', 'boolean'),
    ],
    'Vehicle Condition': [
      AgreementFieldTemplate('Condition Matches Listing', 'boolean'),
      AgreementFieldTemplate('Known Defects / Issues', 'text'),
      AgreementFieldTemplate('Recent Repairs Done', 'text'),
      AgreementFieldTemplate('New Issues Since Listing', 'text'),
      AgreementFieldTemplate(
        'Fuel Level at Handover',
        'select',
        options: 'Full,Three-Quarter,Half,Quarter,Empty',
      ),
      AgreementFieldTemplate('Accessories Included', 'text'),
      AgreementFieldTemplate('Spare Tire Included', 'boolean'),
      AgreementFieldTemplate("Owner's Manual Included", 'boolean'),
      AgreementFieldTemplate('Spare Keys Included', 'boolean'),
      AgreementFieldTemplate('Service Records Available', 'boolean'),
      AgreementFieldTemplate('Modifications Declared', 'text'),
    ],
    'Handover / Delivery': [
      AgreementFieldTemplate(
        'Handover Method',
        'select',
        options: 'Pickup,Delivery',
      ),
      AgreementFieldTemplate('Handover Location', 'text'),
      AgreementFieldTemplate('Delivery Address', 'text'),
      AgreementFieldTemplate('Proposed Handover Date', 'date'),
      AgreementFieldTemplate('Proposed Handover Time', 'text'),
      AgreementFieldTemplate(
        'Transport Arranged By',
        'select',
        options: 'Seller,Buyer,Third Party',
      ),
      AgreementFieldTemplate('Transport Cost', 'number'),
      AgreementFieldTemplate('Seller Contact Number', 'text'),
      AgreementFieldTemplate('Buyer Contact Number', 'text'),
    ],
    'Additional Costs': [
      AgreementFieldTemplate('LTO Transfer Fee', 'number'),
      AgreementFieldTemplate('Insurance Premium', 'number'),
      AgreementFieldTemplate('Towing / Transport Fee', 'number'),
      AgreementFieldTemplate('Pre-Purchase Inspection Fee', 'number'),
      AgreementFieldTemplate('Notarization Fee', 'number'),
      AgreementFieldTemplate('Other Fees', 'number'),
    ],
    'Terms & Conditions': [
      AgreementFieldTemplate('Sold As-Is Condition', 'boolean'),
      AgreementFieldTemplate('Warranty Period', 'text'),
      AgreementFieldTemplate('Warranty Coverage Details', 'text'),
      AgreementFieldTemplate('Return / Refund Policy', 'text'),
      AgreementFieldTemplate('Dispute Resolution Method', 'text'),
      AgreementFieldTemplate('Additional Terms & Conditions', 'text'),
    ],
  };

  /// Get icon for a category
  static String iconForCategory(String category) {
    switch (category) {
      case 'Vehicle Information':
        return 'directions_car';
      case 'Payment Terms':
        return 'payments';
      case 'Document Checklist':
        return 'folder_copy';
      case 'Vehicle Condition':
        return 'build';
      case 'Handover / Delivery':
        return 'local_shipping';
      case 'Additional Costs':
        return 'receipt_long';
      case 'Terms & Conditions':
        return 'gavel';
      default:
        return 'note';
    }
  }
}
