import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for seller transaction operations
/// Handles seller-side transaction management and forms
class SellerTransactionSupabaseDataSource {
  final SupabaseClient _supabase;

  SellerTransactionSupabaseDataSource(this._supabase);

  /// Get all transactions for seller
  /// Joins with vehicles and buyer profiles
  Future<List<Map<String, dynamic>>> getSellerTransactions(
    String sellerId,
  ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            id, agreed_price, deposit_amount, status, created_at, completed_at,
            seller_form_submitted, buyer_form_submitted, seller_confirmed, buyer_confirmed,
            admin_approved, admin_approved_at, delivery_status, delivery_started_at, delivery_completed_at,
            vehicles!vehicle_id(id, brand, model, year, main_image_url),
            user_profiles!buyer_id(id, username, full_name, profile_photo_url)
          ''')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get seller transactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get seller transactions: $e');
    }
  }

  /// Get single transaction detail
  /// Includes all related data
  Future<Map<String, dynamic>> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            vehicles!vehicle_id(*),
            user_profiles!buyer_id(id, username, full_name, email, contact_number, profile_photo_url)
          ''')
          .eq('id', transactionId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get transaction detail: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get transaction detail: $e');
    }
  }

  /// Submit seller form
  /// Inserts into transaction_forms table with seller role
  Future<void> submitSellerForm({
    required String transactionId,
    required double agreedPrice,
    required String paymentMethod,
    required DateTime deliveryDate,
    required String deliveryLocation,
    required bool orcrVerified,
    required bool deedsOfSaleReady,
    required bool plateNumberConfirmed,
    required bool registrationValid,
    required bool noOutstandingLoans,
    required bool mechanicalInspectionDone,
    String additionalTerms = '',
  }) async {
    try {
      // Insert seller form
      await _supabase.from('transaction_forms').insert({
        'transaction_id': transactionId,
        'role': 'seller',
        'agreed_price': agreedPrice,
        'payment_method': paymentMethod,
        'delivery_date': deliveryDate.toIso8601String().split('T')[0],
        'delivery_location': deliveryLocation,
        'orcr_verified': orcrVerified,
        'deeds_of_sale_ready': deedsOfSaleReady,
        'plate_number_confirmed': plateNumberConfirmed,
        'registration_valid': registrationValid,
        'no_outstanding_loans': noOutstandingLoans,
        'mechanical_inspection_done': mechanicalInspectionDone,
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // Update transaction to mark seller form submitted
      await _supabase
          .from('transactions')
          .update({'seller_form_submitted': true})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Seller Form Submitted',
        'description': 'Seller has submitted transaction form for review',
        'event_type': 'form_submitted',
        'actor_name': 'Seller',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit seller form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit seller form: $e');
    }
  }

  /// Confirm seller form (after reviewing buyer's form)
  /// Marks seller as having confirmed the transaction
  Future<void> confirmSellerForm(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .update({'seller_confirmed': true})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Seller Confirmed',
        'description': 'Seller has confirmed transaction details',
        'event_type': 'form_confirmed',
        'actor_name': 'Seller',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to confirm seller form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to confirm seller form: $e');
    }
  }

  /// Submit transaction to admin for approval
  /// Changes status to pending_approval
  Future<void> submitToAdmin(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .update({'status': 'pending_approval'})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Submitted to Admin',
        'description': 'Transaction submitted for admin approval',
        'event_type': 'admin_review',
        'actor_name': 'System',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit to admin: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit to admin: $e');
    }
  }

  /// Update delivery status
  /// Seller updates delivery progress (preparing → in_transit → delivered)
  /// Uses RPC function for proper validation and authorization
  Future<void> updateDeliveryStatus({
    required String transactionId,
    required String sellerId,
    required String deliveryStatus,
  }) async {
    try {
      // Use RPC function for secure update
      await _supabase.rpc(
        'update_delivery_status',
        params: {
          'p_transaction_id': transactionId,
          'p_seller_id': sellerId,
          'p_delivery_status': deliveryStatus,
        },
      );

      // Add timeline event
      String title = '';
      String description = '';
      switch (deliveryStatus) {
        case 'preparing':
          title = 'Preparing Vehicle';
          description = 'Seller is preparing vehicle for delivery';
          break;
        case 'in_transit':
          title = 'On Delivery';
          description = 'Vehicle is being transported to buyer';
          break;
        case 'delivered':
          title = 'Delivered';
          description =
              'Vehicle has been delivered to buyer. Awaiting buyer confirmation.';
          break;
      }

      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': title,
        'description': description,
        'event_type': deliveryStatus == 'delivered' ? 'delivered' : 'started',
        'actor_name': 'Seller',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to update delivery status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update delivery status: $e');
    }
  }

  /// Get seller's form for a transaction
  /// Fetches from transaction_forms table
  Future<Map<String, dynamic>?> getSellerForm(String transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_forms')
          .select()
          .eq('transaction_id', transactionId)
          .eq('role', 'seller')
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get seller form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get seller form: $e');
    }
  }

  /// Get buyer's form for a transaction
  /// So seller can review buyer's submitted form
  Future<Map<String, dynamic>?> getBuyerForm(String transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_forms')
          .select()
          .eq('transaction_id', transactionId)
          .eq('role', 'buyer')
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get buyer form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get buyer form: $e');
    }
  }

  /// Cancel transaction
  /// Sets status to cancelled
  Future<void> cancelTransaction({
    required String transactionId,
    String reason = '',
  }) async {
    try {
      await _supabase
          .from('transactions')
          .update({'status': 'cancelled'})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Transaction Cancelled',
        'description':
            'Transaction was cancelled. ${reason.isNotEmpty ? "Reason: $reason" : ""}',
        'event_type': 'cancelled',
        'actor_name': 'Seller',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }
}
