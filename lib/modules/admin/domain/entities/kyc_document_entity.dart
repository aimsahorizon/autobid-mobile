class KycDocumentEntity {
  final String id;
  final String userId;
  final String statusId;
  final String statusName;

  // User information
  final String firstName;
  final String lastName;
  final String? middleName;
  final String email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? sex;

  // Address
  final String? region;
  final String? province;
  final String? city;
  final String? barangay;
  final String? streetAddress;
  final String? zipcode;

  // National ID
  final String? nationalIdNumber;
  final String nationalIdFrontUrl;
  final String nationalIdBackUrl;

  // Secondary ID
  final String? secondaryGovIdType;
  final String? secondaryGovIdNumber;
  final String? secondaryGovIdFrontUrl;
  final String? secondaryGovIdBackUrl;

  // Proof of Address
  final String? proofOfAddressType;
  final String? proofOfAddressUrl;

  // Selfie
  final String selfieWithIdUrl;

  // Review metadata
  final String? documentType;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewedByName;
  final String? rejectionReason;
  final String? adminNotes;
  final DateTime? expiresAt;

  // Queue metadata
  final String? queueId;
  final String? assignedTo;
  final String? assignedToName;
  final int? priority;
  final DateTime? slaDeadline;

  final DateTime createdAt;
  final DateTime updatedAt;

  const KycDocumentEntity({
    required this.id,
    required this.userId,
    required this.statusId,
    required this.statusName,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    this.phoneNumber,
    this.dateOfBirth,
    this.sex,
    this.region,
    this.province,
    this.city,
    this.barangay,
    this.streetAddress,
    this.zipcode,
    this.nationalIdNumber,
    required this.nationalIdFrontUrl,
    required this.nationalIdBackUrl,
    this.secondaryGovIdType,
    this.secondaryGovIdNumber,
    this.secondaryGovIdFrontUrl,
    this.secondaryGovIdBackUrl,
    this.proofOfAddressType,
    this.proofOfAddressUrl,
    required this.selfieWithIdUrl,
    this.documentType,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewedByName,
    this.rejectionReason,
    this.adminNotes,
    this.expiresAt,
    this.queueId,
    this.assignedTo,
    this.assignedToName,
    this.priority,
    this.slaDeadline,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => statusName == 'pending' || statusName == 'under_review';
  bool get isApproved => statusName == 'approved';
  bool get isRejected => statusName == 'rejected';
  bool get isExpired => statusName == 'expired';

  bool get isSlaAtRisk {
    if (slaDeadline == null) return false;
    final now = DateTime.now();
    final hoursUntilDeadline = slaDeadline!.difference(now).inHours;
    return hoursUntilDeadline <= 6 && hoursUntilDeadline > 0;
  }

  bool get isSlaBreached {
    if (slaDeadline == null) return false;
    return DateTime.now().isAfter(slaDeadline!);
  }

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get fullAddress {
    final parts = [
      streetAddress,
      barangay,
      city,
      province,
      region,
      zipcode,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  int get documentCount {
    int count = 2; // National ID front and back always required
    count += 1; // Selfie with ID always required
    if (secondaryGovIdFrontUrl != null) count++;
    if (secondaryGovIdBackUrl != null) count++;
    if (proofOfAddressUrl != null) count++;
    return count;
  }
}
