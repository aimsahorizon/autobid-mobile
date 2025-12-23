class KycRegistrationEntity {
  final String id; // auth.users id
  final String email;
  final String phoneNumber;
  final String username;

  // Personal Information
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime dateOfBirth;
  final String sex; // M, F

  // Address Information
  final String region;
  final String province;
  final String city;
  final String barangay;
  final String streetAddress;
  final String zipcode;

  // National ID Information
  final String nationalIdNumber;
  final String nationalIdFrontUrl;
  final String nationalIdBackUrl;

  // Secondary Government ID
  final String secondaryGovIdType; // driver_license, passport, umid, etc
  final String secondaryGovIdNumber;
  final String secondaryGovIdFrontUrl;
  final String secondaryGovIdBackUrl;

  // Proof of Address
  final String proofOfAddressType; // utility_bill, bank_statement, government_issued_document, barangay_certificate
  final String proofOfAddressUrl;

  // Selfie with ID
  final String selfieWithIdUrl;

  // Legal acceptance
  final DateTime acceptedTermsAt;
  final DateTime acceptedPrivacyAt;

  // Status Tracking
  final String status; // pending, in_review, approved, rejected
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? adminNotes;

  // Timestamps
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KycRegistrationEntity({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.dateOfBirth,
    required this.sex,
    required this.region,
    required this.province,
    required this.city,
    required this.barangay,
    required this.streetAddress,
    required this.zipcode,
    required this.nationalIdNumber,
    required this.nationalIdFrontUrl,
    required this.nationalIdBackUrl,
    required this.secondaryGovIdType,
    required this.secondaryGovIdNumber,
    required this.secondaryGovIdFrontUrl,
    required this.secondaryGovIdBackUrl,
    required this.proofOfAddressType,
    required this.proofOfAddressUrl,
    required this.selfieWithIdUrl,
    required this.acceptedTermsAt,
    required this.acceptedPrivacyAt,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.adminNotes,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });
}
