import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for buyer transaction operations
/// Handles buyer-side transaction management for won auctions
class BuyerTransactionSupabaseDataSource {
  final SupabaseClient _supabase;

  BuyerTransactionSupabaseDataSource(this._supabase);

  /// Get all transactions for buyer
  /// Joins with vehicles and seller profiles
  Future<List<Map<String, dynamic>>> getBuyerTransactions(String buyerId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            id, agreed_price, deposit_amount, status, created_at, completed_at,
            seller_form_submitted, buyer_form_submitted, seller_confirmed, buyer_confirmed,
            admin_approved, admin_approved_at, delivery_status, delivery_started_at, delivery_completed_at,
            vehicles!vehicle_id(id, brand, model, year, main_image_url),
            user_profiles!seller_id(id, username, full_name, profile_photo_url)
          ''')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get buyer transactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get buyer transactions: $e');
    }
  }

  /// Get single transaction detail
  /// Includes all related data
  Future<Map<String, dynamic>> getTransactionDetail(String transactionId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('''
            *,
            vehicles!vehicle_id(*),
            user_profiles!seller_id(id, username, full_name, email, contact_number, profile_photo_url)
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

  /// Submit buyer form
  /// Inserts into transaction_forms table with buyer role
  Future<void> submitBuyerForm({
    required String transactionId,
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String province,
    required String zipCode,
    required String idType,
    required String idNumber,
    String? idPhotoUrl,
    required String paymentMethod,
    String? bankName,
    String? accountNumber,
    required String deliveryMethod,
    String? deliveryAddress,
    required bool agreedToTerms,
  }) async {
    try {
      // Insert buyer form
      await _supabase.from('transaction_forms').insert({
        'transaction_id': transactionId,
        'role': 'buyer',
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'city': city,
        'province': province,
        'zip_code': zipCode,
        'id_type': idType,
        'id_number': idNumber,
        'id_photo_url': idPhotoUrl,
        'payment_method': paymentMethod,
        'bank_name': bankName,
        'account_number': accountNumber,
        'delivery_method': deliveryMethod,
        'delivery_address': deliveryAddress,
        'agreed_to_terms': agreedToTerms,
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // Update transaction to mark buyer form submitted
      await _supabase
          .from('transactions')
          .update({'buyer_form_submitted': true})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Buyer Form Submitted',
        'description': 'Buyer has submitted transaction form for review',
        'event_type': 'form_submitted',
        'actor_name': 'Buyer',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit buyer form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit buyer form: $e');
    }
  }

  /// Confirm buyer form (after reviewing seller's form)
  /// Marks buyer as having confirmed the transaction
  Future<void> confirmBuyerForm(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .update({'buyer_confirmed': true})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Buyer Confirmed',
        'description': 'Buyer has confirmed transaction details',
        'event_type': 'form_confirmed',
        'actor_name': 'Buyer',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to confirm buyer form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to confirm buyer form: $e');
    }
  }

  /// Get buyer's form for a transaction
  /// Fetches from transaction_forms table
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

  /// Get seller's form for a transaction
  /// So buyer can review seller's submitted form
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

  /// Get user's won bids
  /// Fetches bids with won status
  Future<List<Map<String, dynamic>>> getWonBids(String userId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('id, amount, created_at, vehicles!vehicle_id(id, brand, model, year, main_image_url, status, end_time, current_bid)')
          .eq('bidder_id', userId)
          .eq('status', 'won')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get won bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get won bids: $e');
    }
  }

  /// Get user's active bids
  /// Fetches bids that are still active (auction not ended)
  Future<List<Map<String, dynamic>>> getActiveBids(String userId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('id, amount, created_at, is_auto_bid, max_auto_bid, status, vehicles!vehicle_id(id, brand, model, year, main_image_url, status, end_time, current_bid)')
          .eq('bidder_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get active bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get active bids: $e');
    }
  }

  /// Get user's lost bids
  /// Fetches bids where user was outbid or auction ended without winning
  Future<List<Map<String, dynamic>>> getLostBids(String userId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('id, amount, created_at, status, vehicles!vehicle_id(id, brand, model, year, main_image_url, status, end_time, current_bid)')
          .eq('bidder_id', userId)
          .or('status.eq.outbid,status.eq.lost')
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get lost bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get lost bids: $e');
    }
  }

  /// Cancel transaction (buyer side)
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
        'description': 'Transaction was cancelled by buyer. ${reason.isNotEmpty ? "Reason: $reason" : ""}',
        'event_type': 'cancelled',
        'actor_name': 'Buyer',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }
}
