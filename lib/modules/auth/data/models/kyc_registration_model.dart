import '../../domain/entities/kyc_registration_entity.dart';

class KycRegistrationModel extends KycRegistrationEntity {
  const KycRegistrationModel({
    required super.id,
    required super.email,
    required super.phoneNumber,
    required super.username,
    required super.firstName,
    required super.lastName,
    super.middleName,
    required super.dateOfBirth,
    required super.sex,
    required super.region,
    required super.province,
    required super.city,
    required super.barangay,
    required super.streetAddress,
    required super.zipcode,
    required super.nationalIdNumber,
    required super.nationalIdFrontUrl,
    required super.nationalIdBackUrl,
    required super.secondaryGovIdType,
    required super.secondaryGovIdNumber,
    required super.secondaryGovIdFrontUrl,
    required super.secondaryGovIdBackUrl,
    required super.proofOfAddressType,
    required super.proofOfAddressUrl,
    required super.selfieWithIdUrl,
    required super.acceptedTermsAt,
    required super.acceptedPrivacyAt,
    super.status,
    super.reviewedBy,
    super.reviewedAt,
    super.rejectionReason,
    super.adminNotes,
    super.submittedAt,
    super.createdAt,
    super.updatedAt,
  });

  // Factory constructor to create model from JSON (from Supabase)
  factory KycRegistrationModel.fromJson(Map<String, dynamic> json) {
    return KycRegistrationModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      middleName: json['middle_name'] as String?,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      sex: json['sex'] as String,
      region: json['region'] as String,
      province: json['province'] as String,
      city: json['city'] as String,
      barangay: json['barangay'] as String,
      streetAddress: json['street_address'] as String,
      zipcode: json['zipcode'] as String,
      nationalIdNumber: json['national_id_number'] as String,
      nationalIdFrontUrl: json['national_id_front_url'] as String,
      nationalIdBackUrl: json['national_id_back_url'] as String,
      secondaryGovIdType: json['secondary_gov_id_type'] as String,
      secondaryGovIdNumber: json['secondary_gov_id_number'] as String,
      secondaryGovIdFrontUrl: json['secondary_gov_id_front_url'] as String,
      secondaryGovIdBackUrl: json['secondary_gov_id_back_url'] as String,
      proofOfAddressType: json['proof_of_address_type'] as String,
      proofOfAddressUrl: json['proof_of_address_url'] as String,
      selfieWithIdUrl: json['selfie_with_id_url'] as String,
      acceptedTermsAt: json['accepted_terms_at'] != null
          ? DateTime.parse(json['accepted_terms_at'] as String)
          : DateTime.now(),
      acceptedPrivacyAt: json['accepted_privacy_at'] != null
          ? DateTime.parse(json['accepted_privacy_at'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert model to JSON (to send to Supabase)
  Map<String, dynamic> toJson() {
    // Automatically generate display_name from first and last name
    final displayName = middleName != null && middleName!.isNotEmpty
        ? '$firstName $middleName $lastName'
        : '$firstName $lastName';

    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'date_of_birth': dateOfBirth.toIso8601String().split(
        'T',
      )[0], // YYYY-MM-DD format
      'sex': sex,
      'region': region,
      'province': province,
      'city': city,
      'barangay': barangay,
      'street_address': streetAddress,
      'zipcode': zipcode,
      'national_id_number': nationalIdNumber,
      'national_id_front_url': nationalIdFrontUrl,
      'national_id_back_url': nationalIdBackUrl,
      'secondary_gov_id_type': secondaryGovIdType,
      'secondary_gov_id_number': secondaryGovIdNumber,
      'secondary_gov_id_front_url': secondaryGovIdFrontUrl,
      'secondary_gov_id_back_url': secondaryGovIdBackUrl,
      'proof_of_address_type': proofOfAddressType,
      'proof_of_address_url': proofOfAddressUrl,
      'selfie_with_id_url': selfieWithIdUrl,
      'accepted_terms_at': acceptedTermsAt.toIso8601String(),
      'accepted_privacy_at': acceptedPrivacyAt.toIso8601String(),
      'display_name': displayName, // Auto-generated from first/middle/last name
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'submitted_at': submittedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields (useful for state management)
  KycRegistrationModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? username,
    String? firstName,
    String? lastName,
    String? middleName,
    DateTime? dateOfBirth,
    String? sex,
    String? region,
    String? province,
    String? city,
    String? barangay,
    String? streetAddress,
    String? zipcode,
    String? nationalIdNumber,
    String? nationalIdFrontUrl,
    String? nationalIdBackUrl,
    String? secondaryGovIdType,
    String? secondaryGovIdNumber,
    String? secondaryGovIdFrontUrl,
    String? secondaryGovIdBackUrl,
    String? proofOfAddressType,
    String? proofOfAddressUrl,
    String? selfieWithIdUrl,
    DateTime? acceptedTermsAt,
    DateTime? acceptedPrivacyAt,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? adminNotes,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return KycRegistrationModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      streetAddress: streetAddress ?? this.streetAddress,
      zipcode: zipcode ?? this.zipcode,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      nationalIdFrontUrl: nationalIdFrontUrl ?? this.nationalIdFrontUrl,
      nationalIdBackUrl: nationalIdBackUrl ?? this.nationalIdBackUrl,
      secondaryGovIdType: secondaryGovIdType ?? this.secondaryGovIdType,
      secondaryGovIdNumber: secondaryGovIdNumber ?? this.secondaryGovIdNumber,
      secondaryGovIdFrontUrl:
          secondaryGovIdFrontUrl ?? this.secondaryGovIdFrontUrl,
      secondaryGovIdBackUrl:
          secondaryGovIdBackUrl ?? this.secondaryGovIdBackUrl,
      proofOfAddressType: proofOfAddressType ?? this.proofOfAddressType,
      proofOfAddressUrl: proofOfAddressUrl ?? this.proofOfAddressUrl,
      selfieWithIdUrl: selfieWithIdUrl ?? this.selfieWithIdUrl,
      acceptedTermsAt: acceptedTermsAt ?? this.acceptedTermsAt,
      acceptedPrivacyAt: acceptedPrivacyAt ?? this.acceptedPrivacyAt,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      adminNotes: adminNotes ?? this.adminNotes,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
