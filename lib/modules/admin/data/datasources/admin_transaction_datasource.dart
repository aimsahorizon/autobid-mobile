import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/admin_transaction_entity.dart';

/// Supabase datasource for admin transaction management
class AdminTransactionDataSource {
  final SupabaseClient _supabase;

  AdminTransactionDataSource(this._supabase);

  /// Get all transactions for admin review
  Future<List<AdminTransactionEntity>> getTransactions({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print(
        '[AdminTransactionDataSource] getTransactions called, filter: $statusFilter',
      );

      // Build query with filter first, then order and range
      final baseQuery = _supabase.from('auction_transactions').select('''
            *,
            auctions!inner(title, auction_vehicles(brand, model)),
            seller:users!auction_transactions_seller_id_fkey(display_name, email),
            buyer:users!auction_transactions_buyer_id_fkey(display_name, email)
          ''');

      final List<dynamic> response;
      if (statusFilter != null && statusFilter != 'all') {
        response = await baseQuery
            .eq('status', statusFilter)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      } else {
        response = await baseQuery
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);
      }

      print('[AdminTransactionDataSource] Got ${response.length} transactions');
      if (response.isNotEmpty) {
        print(
          '[AdminTransactionDataSource] First transaction: ${response.first}',
        );
      }

      return response.map((data) => _mapToEntity(data)).toList();
    } catch (e) {
      print('[AdminTransactionDataSource] Error getting transactions: $e');
      rethrow;
    }
  }

  /// Get transactions pending admin review (both confirmed, not yet approved)
  Future<List<AdminTransactionEntity>> getPendingReviewTransactions() async {
    try {
      final response = await _supabase
          .from('auction_transactions')
          .select('''
            *,
            auctions!inner(title, auction_vehicles(brand, model)),
            seller:users!auction_transactions_seller_id_fkey(display_name, email),
            buyer:users!auction_transactions_buyer_id_fkey(display_name, email)
          ''')
          .eq('seller_form_submitted', true)
          .eq('buyer_form_submitted', true)
          .eq('seller_confirmed', true)
          .eq('buyer_confirmed', true)
          .eq('admin_approved', false)
          .eq('status', 'in_transaction')
          .order('updated_at', ascending: true);

      return (response as List).map((data) => _mapToEntity(data)).toList();
    } catch (e) {
      print('[AdminTransactionDataSource] Error getting pending reviews: $e');
      rethrow;
    }
  }

  /// Get transaction by ID with full details
  Future<AdminTransactionEntity?> getTransactionById(String id) async {
    try {
      final response = await _supabase
          .from('auction_transactions')
          .select('''
            *,
            auctions!inner(title, auction_vehicles(brand, model)),
            seller:users!auction_transactions_seller_id_fkey(display_name, email),
            buyer:users!auction_transactions_buyer_id_fkey(display_name, email)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return _mapToEntity(response);
    } catch (e) {
      print('[AdminTransactionDataSource] Error getting transaction: $e');
      rethrow;
    }
  }

  /// Get forms for a transaction
  Future<List<AdminTransactionFormEntity>> getTransactionForms(
    String transactionId,
  ) async {
    try {
      final response = await _supabase
          .from('transaction_forms')
          .select()
          .eq('transaction_id', transactionId)
          .order('role', ascending: true);

      return (response as List).map((data) => _mapToFormEntity(data)).toList();
    } catch (e) {
      print('[AdminTransactionDataSource] Error getting forms: $e');
      return [];
    }
  }

  /// Approve a transaction
  Future<bool> approveTransaction(
    String transactionId, {
    String? adminNotes,
  }) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('auction_transactions')
          .update({
            'admin_approved': true,
            'admin_approved_at': DateTime.now().toIso8601String(),
            'admin_notes': adminNotes,
            'reviewed_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // Add timeline event
      await _addTimelineEvent(
        transactionId,
        'Admin Approved',
        'Transaction approved by admin. Proceed with delivery.',
        'admin_approved',
      );

      return true;
    } catch (e) {
      print('[AdminTransactionDataSource] Error approving: $e');
      return false;
    }
  }

  /// Reject/fail a transaction
  Future<bool> rejectTransaction(
    String transactionId, {
    required String reason,
  }) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('auction_transactions')
          .update({
            'status': 'deal_failed',
            'admin_notes': reason,
            'reviewed_by': adminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // Add timeline event
      await _addTimelineEvent(
        transactionId,
        'Transaction Rejected',
        'Admin rejected: $reason',
        'cancelled',
      );

      return true;
    } catch (e) {
      print('[AdminTransactionDataSource] Error rejecting: $e');
      return false;
    }
  }

  /// Get transaction statistics
  Future<AdminTransactionStats> getStats() async {
    try {
      print('[AdminTransactionDataSource] getStats called');
      final response = await _supabase
          .from('auction_transactions')
          .select(
            'id, status, seller_form_submitted, buyer_form_submitted, seller_confirmed, buyer_confirmed, admin_approved',
          );

      final transactions = response as List;
      print(
        '[AdminTransactionDataSource] Stats query got ${transactions.length} transactions',
      );

      int pendingReview = 0;
      int awaitingConfirmation = 0;
      int inProgress = 0;
      int approved = 0;
      int completed = 0;
      int failed = 0;

      for (final t in transactions) {
        final status = t['status'] as String?;
        final sellerFormSubmitted =
            t['seller_form_submitted'] as bool? ?? false;
        final buyerFormSubmitted = t['buyer_form_submitted'] as bool? ?? false;
        final sellerConfirmed = t['seller_confirmed'] as bool? ?? false;
        final buyerConfirmed = t['buyer_confirmed'] as bool? ?? false;
        final adminApproved = t['admin_approved'] as bool? ?? false;

        if (status == 'sold') {
          completed++;
        } else if (status == 'deal_failed') {
          failed++;
        } else if (adminApproved) {
          approved++;
        } else if (sellerFormSubmitted &&
            buyerFormSubmitted &&
            sellerConfirmed &&
            buyerConfirmed) {
          pendingReview++;
        } else if (sellerFormSubmitted && buyerFormSubmitted) {
          awaitingConfirmation++;
        } else {
          inProgress++;
        }
      }

      return AdminTransactionStats(
        total: transactions.length,
        pendingReview: pendingReview,
        awaitingConfirmation: awaitingConfirmation,
        inProgress: inProgress,
        approved: approved,
        completed: completed,
        failed: failed,
      );
    } catch (e) {
      print('[AdminTransactionDataSource] Error getting stats: $e');
      return const AdminTransactionStats(
        total: 0,
        pendingReview: 0,
        awaitingConfirmation: 0,
        inProgress: 0,
        approved: 0,
        completed: 0,
        failed: 0,
      );
    }
  }

  /// Add timeline event
  Future<void> _addTimelineEvent(
    String transactionId,
    String title,
    String description,
    String eventType,
  ) async {
    try {
      final adminId = _supabase.auth.currentUser?.id;
      final adminName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Admin';

      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': title,
        'description': description,
        'event_type': eventType,
        'actor_id': adminId,
        'actor_name': adminName,
      });
    } catch (e) {
      print('[AdminTransactionDataSource] Error adding timeline: $e');
    }
  }

  AdminTransactionEntity _mapToEntity(Map<String, dynamic> data) {
    // Get car name
    String carName = 'Vehicle';
    if (data['auctions'] is Map) {
      final auctions = data['auctions'] as Map<String, dynamic>;
      final vehicles = auctions['auction_vehicles'];
      if (vehicles is List && vehicles.isNotEmpty) {
        final v = vehicles.first;
        carName = '${v['brand'] ?? ''} ${v['model'] ?? ''}'.trim();
      } else if (auctions['title'] != null) {
        carName = auctions['title'] as String;
      }
    }

    // Get seller/buyer names
    String sellerName = 'Unknown Seller';
    String buyerName = 'Unknown Buyer';

    if (data['seller'] is Map) {
      sellerName =
          data['seller']['display_name'] as String? ?? 'Unknown Seller';
    }
    if (data['buyer'] is Map) {
      buyerName = data['buyer']['display_name'] as String? ?? 'Unknown Buyer';
    }

    return AdminTransactionEntity(
      id: data['id'] as String,
      auctionId: data['auction_id'] as String,
      sellerId: data['seller_id'] as String,
      buyerId: data['buyer_id'] as String,
      sellerName: sellerName,
      buyerName: buyerName,
      carName: carName,
      carImageUrl: '', // We don't need image in admin view
      agreedPrice: (data['agreed_price'] as num).toDouble(),
      status: data['status'] as String? ?? 'in_transaction',
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'] as String)
          : null,
      sellerFormSubmitted: data['seller_form_submitted'] as bool? ?? false,
      buyerFormSubmitted: data['buyer_form_submitted'] as bool? ?? false,
      sellerConfirmed: data['seller_confirmed'] as bool? ?? false,
      buyerConfirmed: data['buyer_confirmed'] as bool? ?? false,
      adminApproved: data['admin_approved'] as bool? ?? false,
      adminApprovedAt: data['admin_approved_at'] != null
          ? DateTime.parse(data['admin_approved_at'] as String)
          : null,
      adminNotes: data['admin_notes'] as String?,
      reviewedBy: data['reviewed_by'] as String?,
    );
  }

  AdminTransactionFormEntity _mapToFormEntity(Map<String, dynamic> data) {
    return AdminTransactionFormEntity(
      id: data['id'] as String,
      transactionId: data['transaction_id'] as String,
      role: data['role'] as String,
      status: data['status'] as String? ?? 'draft',
      agreedPrice: (data['agreed_price'] as num).toDouble(),
      paymentMethod: data['payment_method'] as String?,
      deliveryDate: data['delivery_date'] != null
          ? DateTime.parse(data['delivery_date'] as String)
          : null,
      deliveryLocation: data['delivery_location'] as String?,
      orCrVerified: data['or_cr_verified'] as bool? ?? false,
      deedsOfSaleReady: data['deeds_of_sale_ready'] as bool? ?? false,
      plateNumberConfirmed: data['plate_number_confirmed'] as bool? ?? false,
      registrationValid: data['registration_valid'] as bool? ?? false,
      noOutstandingLoans: data['no_outstanding_loans'] as bool? ?? false,
      mechanicalInspectionDone:
          data['mechanical_inspection_done'] as bool? ?? false,
      additionalTerms: data['additional_terms'] as String?,
      reviewNotes: data['review_notes'] as String?,
      submittedAt: data['submitted_at'] != null
          ? DateTime.parse(data['submitted_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}
