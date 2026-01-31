import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kyc_document_model.dart';
import '../models/kyc_stats_model.dart';

class KycSupabaseDataSource {
  final SupabaseClient _supabase;

  KycSupabaseDataSource(this._supabase);

  /// Get KYC statistics for admin dashboard
  Future<KycStatsModel> getKycStats() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      // Get all KYC documents with their statuses
      final kycResponse = await _supabase.from('kyc_documents').select('''
            id,
            status_id,
            kyc_statuses(status_name),
            kyc_review_queue(assigned_to, sla_deadline)
          ''');

      final kycDocs = (kycResponse as List).cast<Map<String, dynamic>>();

      int pendingCount = 0;
      int underReviewCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      int expiredCount = 0;
      int slaAtRiskCount = 0;
      int slaBreachedCount = 0;
      int assignedToMeCount = 0;

      final now = DateTime.now();

      for (final doc in kycDocs) {
        final statusData = doc['kyc_statuses'];
        final queueData = doc['kyc_review_queue'];

        String statusName = 'pending';
        if (statusData is Map<String, dynamic>) {
          statusName = statusData['status_name'] as String? ?? 'pending';
        } else if (statusData is List && statusData.isNotEmpty) {
          statusName =
              (statusData[0] as Map<String, dynamic>)['status_name']
                  as String? ??
              'pending';
        }

        // Count by status
        switch (statusName) {
          case 'pending':
            pendingCount++;
            break;
          case 'under_review':
            underReviewCount++;
            break;
          case 'approved':
            approvedCount++;
            break;
          case 'rejected':
            rejectedCount++;
            break;
          case 'expired':
            expiredCount++;
            break;
        }

        // Check SLA
        if (queueData != null) {
          Map<String, dynamic> queue;
          if (queueData is Map<String, dynamic>) {
            queue = queueData;
          } else if (queueData is List && queueData.isNotEmpty) {
            queue = queueData[0] as Map<String, dynamic>;
          } else {
            continue;
          }

          final slaDeadline = queue['sla_deadline'] as String?;
          final assignedTo = queue['assigned_to'] as String?;

          if (slaDeadline != null) {
            final deadline = DateTime.parse(slaDeadline);
            final hoursUntilDeadline = deadline.difference(now).inHours;

            if (now.isAfter(deadline)) {
              slaBreachedCount++;
            } else if (hoursUntilDeadline <= 6) {
              slaAtRiskCount++;
            }
          }

          if (assignedTo == currentUserId) {
            assignedToMeCount++;
          }
        }
      }

      return KycStatsModel(
        totalSubmissions: kycDocs.length,
        pendingReview: pendingCount,
        underReview: underReviewCount,
        approved: approvedCount,
        rejected: rejectedCount,
        expired: expiredCount,
        slaAtRisk: slaAtRiskCount,
        slaBreached: slaBreachedCount,
        assignedToMe: assignedToMeCount,
      );
    } catch (e) {
      throw Exception('Failed to fetch KYC stats: $e');
    }
  }

  /// Get all KYC submissions with optional status filter
  Future<List<KycDocumentModel>> getKycSubmissions({String? status}) async {
    try {
      var query = _supabase.from('kyc_documents').select('''
            id,
            user_id,
            status_id,
            national_id_number,
            national_id_front_url,
            national_id_back_url,
            secondary_gov_id_type,
            secondary_gov_id_number,
            secondary_gov_id_front_url,
            secondary_gov_id_back_url,
            proof_of_address_type,
            proof_of_address_url,
            selfie_with_id_url,
            document_type,
            submitted_at,
            reviewed_at,
            reviewed_by,
            rejection_reason,
            admin_notes,
            expires_at,
            created_at,
            updated_at,
            kyc_statuses(status_name),
            user:users!kyc_documents_user_id_fkey(first_name, last_name, middle_name, email, phone_number, date_of_birth, sex),
            kyc_review_queue(id, assigned_to, priority, sla_deadline),
            reviewed_by_admin:admin_users!kyc_documents_reviewed_by_fkey(user:users!admin_users_user_id_fkey(first_name, last_name))
          ''');

      // Filter by status if provided
      if (status != null && status != 'all') {
        final statusId = await _getKycStatusId(status);
        query = query.eq('status_id', statusId);
      }

      // Order by priority and submission time
      final response = await query.order('submitted_at', ascending: true);

      final kycDocs = (response as List).cast<Map<String, dynamic>>();

      // Fetch addresses for all users
      final userIds = kycDocs
          .map((doc) => doc['user_id'] as String)
          .toSet()
          .toList();
      final addressesResponse = await _supabase
          .from('user_addresses')
          .select(
            'user_id, region, province, city, barangay, street_address, zipcode',
          )
          .inFilter('user_id', userIds)
          .eq('is_default', true);

      // Create a map of user_id to address
      final addressMap = <String, Map<String, dynamic>>{};
      for (final addr
          in (addressesResponse as List).cast<Map<String, dynamic>>()) {
        addressMap[addr['user_id'] as String] = addr;
      }

      // Merge address data into KYC documents
      for (final doc in kycDocs) {
        final userId = doc['user_id'] as String;
        if (addressMap.containsKey(userId)) {
          doc['address'] = addressMap[userId];
        }
      }

      return kycDocs.map((json) => _parseKycDocument(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch KYC submissions: $e');
    }
  }

  /// Get pending KYC submissions (for review queue)
  Future<List<KycDocumentModel>> getPendingKycSubmissions() async {
    try {
      final pendingStatusId = await _getKycStatusId('pending');
      final underReviewStatusId = await _getKycStatusId('under_review');

      final response = await _supabase
          .from('kyc_documents')
          .select('''
            id,
            user_id,
            status_id,
            national_id_number,
            national_id_front_url,
            national_id_back_url,
            secondary_gov_id_type,
            secondary_gov_id_number,
            secondary_gov_id_front_url,
            secondary_gov_id_back_url,
            proof_of_address_type,
            proof_of_address_url,
            selfie_with_id_url,
            document_type,
            submitted_at,
            reviewed_at,
            reviewed_by,
            rejection_reason,
            admin_notes,
            expires_at,
            created_at,
            updated_at,
            kyc_statuses(status_name),
            user:users!kyc_documents_user_id_fkey(first_name, last_name, middle_name, email, phone_number, date_of_birth, sex),
            kyc_review_queue(id, assigned_to, priority, sla_deadline)
          ''')
          .inFilter('status_id', [pendingStatusId, underReviewStatusId])
          .order('submitted_at', ascending: true);

      final kycDocs = (response as List).cast<Map<String, dynamic>>();

      // Fetch addresses for all users
      final userIds = kycDocs
          .map((doc) => doc['user_id'] as String)
          .toSet()
          .toList();
      if (userIds.isNotEmpty) {
        final addressesResponse = await _supabase
            .from('user_addresses')
            .select(
              'user_id, region, province, city, barangay, street_address, zipcode',
            )
            .inFilter('user_id', userIds)
            .eq('is_default', true);

        // Create a map of user_id to address
        final addressMap = <String, Map<String, dynamic>>{};
        for (final addr
            in (addressesResponse as List).cast<Map<String, dynamic>>()) {
          addressMap[addr['user_id'] as String] = addr;
        }

        // Merge address data into KYC documents
        for (final doc in kycDocs) {
          final userId = doc['user_id'] as String;
          if (addressMap.containsKey(userId)) {
            doc['address'] = addressMap[userId];
          }
        }
      }

      return kycDocs.map((json) => _parseKycDocument(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending KYC submissions: $e');
    }
  }

  /// Get a single KYC document by ID
  Future<KycDocumentModel> getKycDocument(String kycDocumentId) async {
    try {
      final response = await _supabase
          .from('kyc_documents')
          .select('''
            id,
            user_id,
            status_id,
            national_id_number,
            national_id_front_url,
            national_id_back_url,
            secondary_gov_id_type,
            secondary_gov_id_number,
            secondary_gov_id_front_url,
            secondary_gov_id_back_url,
            proof_of_address_type,
            proof_of_address_url,
            selfie_with_id_url,
            document_type,
            submitted_at,
            reviewed_at,
            reviewed_by,
            rejection_reason,
            admin_notes,
            expires_at,
            created_at,
            updated_at,
            kyc_statuses(status_name),
            user:users!kyc_documents_user_id_fkey(first_name, last_name, middle_name, email, phone_number, date_of_birth, sex),
            kyc_review_queue(id, assigned_to, priority, sla_deadline),
            reviewed_by_admin:admin_users!kyc_documents_reviewed_by_fkey(user:users!admin_users_user_id_fkey(first_name, last_name))
          ''')
          .eq('id', kycDocumentId)
          .single();

      final kycDoc = response;

      // Fetch address for this user
      final userId = kycDoc['user_id'] as String;
      final addressResponse = await _supabase
          .from('user_addresses')
          .select(
            'user_id, region, province, city, barangay, street_address, zipcode',
          )
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (addressResponse != null) {
        kycDoc['address'] = addressResponse;
      }

      return _parseKycDocument(kycDoc);
    } catch (e) {
      throw Exception('Failed to fetch KYC document: $e');
    }
  }

  /// Approve a KYC document
  Future<void> approveKyc(String kycDocumentId, {String? notes}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get admin_users.id for the current user
      final adminUserResponse = await _supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final adminUserId = adminUserResponse['id'] as String;

      // Call the approve_kyc RPC function
      final result = await _supabase.rpc(
        'approve_kyc',
        params: {'p_kyc_document_id': kycDocumentId, 'p_admin_id': adminUserId},
      );

      if (result != null && result['success'] == false) {
        throw Exception(result['message'] ?? 'Failed to approve KYC');
      }

      // Update admin notes if provided
      if (notes != null && notes.isNotEmpty) {
        await _supabase
            .from('kyc_documents')
            .update({'admin_notes': notes})
            .eq('id', kycDocumentId);
      }
    } catch (e) {
      throw Exception('Failed to approve KYC: $e');
    }
  }

  /// Reject a KYC document
  Future<void> rejectKyc(
    String kycDocumentId,
    String reason, {
    String? notes,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get admin_users.id for the current user
      final adminUserResponse = await _supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final adminUserId = adminUserResponse['id'] as String;

      // Call the reject_kyc RPC function
      final result = await _supabase.rpc(
        'reject_kyc',
        params: {
          'p_kyc_document_id': kycDocumentId,
          'p_admin_id': adminUserId,
          'p_reason': reason,
        },
      );

      if (result != null && result['success'] == false) {
        throw Exception(result['message'] ?? 'Failed to reject KYC');
      }

      // Update admin notes if provided
      if (notes != null && notes.isNotEmpty) {
        await _supabase
            .from('kyc_documents')
            .update({'admin_notes': notes})
            .eq('id', kycDocumentId);
      }
    } catch (e) {
      throw Exception('Failed to reject KYC: $e');
    }
  }

  /// Assign KYC document to an admin for review
  Future<void> assignKycToAdmin(String kycDocumentId, String adminId) async {
    try {
      await _supabase
          .from('kyc_review_queue')
          .update({'assigned_to': adminId})
          .eq('kyc_document_id', kycDocumentId);

      // Update status to under_review
      final underReviewStatusId = await _getKycStatusId('under_review');
      await _supabase
          .from('kyc_documents')
          .update({
            'status_id': underReviewStatusId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kycDocumentId);
    } catch (e) {
      throw Exception('Failed to assign KYC to admin: $e');
    }
  }

  /// Get signed URL for a KYC document file
  Future<String> getDocumentUrl(String filePath) async {
    try {
      final signedUrl = await _supabase.storage
          .from('kyc-documents')
          .createSignedUrl(filePath, 3600); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get document URL: $e');
    }
  }

  /// Helper: Get KYC status ID from status name
  Future<String> _getKycStatusId(String statusName) async {
    final response = await _supabase
        .from('kyc_statuses')
        .select('id')
        .eq('status_name', statusName)
        .single();

    return response['id'] as String;
  }

  /// Helper: Parse KYC document from JSON
  KycDocumentModel _parseKycDocument(Map<String, dynamic> json) {
    try {
      // Extract status name
      final statusData = json['kyc_statuses'];
      String statusName = 'pending';
      if (statusData is Map<String, dynamic>) {
        statusName = statusData['status_name'] as String? ?? 'pending';
      } else if (statusData is List && statusData.isNotEmpty) {
        statusName =
            (statusData[0] as Map<String, dynamic>)['status_name'] as String? ??
            'pending';
      }

      // Extract user data (using 'user' alias from query)
      final userData = json['user'];
      String firstName = 'Unknown';
      String lastName = 'User';
      String? middleName;
      String email = '';
      String? phoneNumber;
      DateTime? dateOfBirth;
      String? sex;

      if (userData is Map<String, dynamic>) {
        firstName = userData['first_name'] as String? ?? 'Unknown';
        lastName = userData['last_name'] as String? ?? 'User';
        middleName = userData['middle_name'] as String?;
        email = userData['email'] as String? ?? '';
        phoneNumber = userData['phone_number'] as String?;
        dateOfBirth = userData['date_of_birth'] != null
            ? DateTime.parse(userData['date_of_birth'] as String)
            : null;
        sex = userData['sex'] as String?;
      }

      // Extract address data from the separate 'address' key we added
      final addressData = json['address'];
      String? region;
      String? province;
      String? city;
      String? barangay;
      String? streetAddress;
      String? zipcode;

      if (addressData is Map<String, dynamic>) {
        region = addressData['region'] as String?;
        province = addressData['province'] as String?;
        city = addressData['city'] as String?;
        barangay = addressData['barangay'] as String?;
        streetAddress = addressData['street_address'] as String?;
        zipcode = addressData['zipcode'] as String?;
      }

      // Extract queue data
      final queueData = json['kyc_review_queue'];
      String? queueId;
      String? assignedTo;
      int? priority;
      DateTime? slaDeadline;

      if (queueData is Map<String, dynamic>) {
        queueId = queueData['id'] as String?;
        assignedTo = queueData['assigned_to'] as String?;
        priority = queueData['priority'] as int?;
        slaDeadline = queueData['sla_deadline'] != null
            ? DateTime.parse(queueData['sla_deadline'] as String)
            : null;
      } else if (queueData is List && queueData.isNotEmpty) {
        final queue = queueData[0] as Map<String, dynamic>;
        queueId = queue['id'] as String?;
        assignedTo = queue['assigned_to'] as String?;
        priority = queue['priority'] as int?;
        slaDeadline = queue['sla_deadline'] != null
            ? DateTime.parse(queue['sla_deadline'] as String)
            : null;
      }

      // Extract reviewer data
      final reviewerData = json['reviewed_by_admin'];
      String? reviewedByName;

      if (reviewerData is Map<String, dynamic>) {
        final reviewerUserData = reviewerData['user'];
        if (reviewerUserData is Map<String, dynamic>) {
          final reviewerFirstName =
              reviewerUserData['first_name'] as String? ?? '';
          final reviewerLastName =
              reviewerUserData['last_name'] as String? ?? '';
          reviewedByName = '$reviewerFirstName $reviewerLastName'.trim();
        }
      }

      return KycDocumentModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        statusId: json['status_id'] as String,
        statusName: statusName,
        firstName: firstName,
        lastName: lastName,
        middleName: middleName,
        email: email,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        sex: sex,
        region: region,
        province: province,
        city: city,
        barangay: barangay,
        streetAddress: streetAddress,
        zipcode: zipcode,
        nationalIdNumber: json['national_id_number'] as String?,
        nationalIdFrontUrl: json['national_id_front_url'] as String,
        nationalIdBackUrl: json['national_id_back_url'] as String,
        secondaryGovIdType: json['secondary_gov_id_type'] as String?,
        secondaryGovIdNumber: json['secondary_gov_id_number'] as String?,
        secondaryGovIdFrontUrl: json['secondary_gov_id_front_url'] as String?,
        secondaryGovIdBackUrl: json['secondary_gov_id_back_url'] as String?,
        proofOfAddressType: json['proof_of_address_type'] as String?,
        proofOfAddressUrl: json['proof_of_address_url'] as String?,
        selfieWithIdUrl: json['selfie_with_id_url'] as String,
        documentType: json['document_type'] as String?,
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.parse(json['reviewed_at'] as String)
            : null,
        reviewedBy: json['reviewed_by'] as String?,
        reviewedByName: reviewedByName,
        rejectionReason: json['rejection_reason'] as String?,
        adminNotes: json['admin_notes'] as String?,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        queueId: queueId,
        assignedTo: assignedTo,
        assignedToName: null,
        priority: priority,
        slaDeadline: slaDeadline,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    } catch (e, stackTrace) {
      debugPrint('[KYC] ERROR parsing KYC document: $e');
      debugPrint('[KYC] Stack trace: $stackTrace');
      debugPrint('[KYC] JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}
