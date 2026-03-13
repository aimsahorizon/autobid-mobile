import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installment_plan_model.dart';
import '../models/installment_payment_model.dart';
import '../models/payment_attempt_model.dart';
import '../../domain/entities/installment_plan_entity.dart';
import '../../domain/entities/installment_payment_entity.dart';
import '../../domain/entities/payment_attempt_entity.dart';

/// Datasource for managing installment plans and payments via Supabase
class InstallmentSupabaseDatasource {
  final SupabaseClient _supabase;

  InstallmentSupabaseDatasource({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  // =========================================================================
  // Installment Plan Operations
  // =========================================================================

  /// Fetch installment plan for a transaction
  Future<InstallmentPlanEntity?> getInstallmentPlan(
    String transactionId,
  ) async {
    try {
      final response = await _supabase
          .from('installment_plans')
          .select()
          .eq('transaction_id', transactionId)
          .maybeSingle();

      if (response == null) return null;
      return InstallmentPlanModel.fromJson(response).toEntity();
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error fetching plan: $e');
      rethrow;
    }
  }

  /// Create a new installment plan and generate payment schedule immediately
  Future<InstallmentPlanEntity> createInstallmentPlan({
    required String transactionId,
    required double totalAmount,
    required double downPayment,
    required int numInstallments,
    required String frequency,
    required DateTime startDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final remaining = totalAmount - downPayment;

      final data = {
        'transaction_id': transactionId,
        'total_amount': totalAmount,
        'down_payment': downPayment,
        'remaining_amount': remaining,
        'total_paid': 0.0,
        'num_installments': numInstallments,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T').first,
        'proposed_by': userId,
      };

      final response = await _supabase
          .from('installment_plans')
          .insert(data)
          .select()
          .single();

      final plan = InstallmentPlanModel.fromJson(response).toEntity();

      // Generate payment schedule immediately
      await generatePaymentSchedule(
        planId: plan.id,
        downPayment: plan.downPayment,
        remaining: plan.remainingAmount,
        numInstallments: plan.numInstallments,
        frequency: plan.frequency,
        startDate: DateTime.now(),
      );

      // Update transaction payment_method
      await _supabase
          .from('auction_transactions')
          .update({'payment_method': 'installment'})
          .eq('id', transactionId);

      return plan;
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error creating plan: $e');
      rethrow;
    }
  }

  /// Update an existing plan and regenerate payment schedule
  Future<InstallmentPlanEntity> updateInstallmentPlan({
    required String planId,
    required String transactionId,
    required double totalAmount,
    required double downPayment,
    required int numInstallments,
    required String frequency,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final remaining = totalAmount - downPayment;

      // Old payments are deleted by the RPC function
      final data = {
        'total_amount': totalAmount,
        'down_payment': downPayment,
        'remaining_amount': remaining,
        'total_paid': 0.0,
        'num_installments': numInstallments,
        'frequency': frequency,
        'proposed_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('installment_plans')
          .update(data)
          .eq('id', planId)
          .select()
          .single();

      final plan = InstallmentPlanModel.fromJson(response).toEntity();

      // Regenerate payment schedule
      await generatePaymentSchedule(
        planId: plan.id,
        downPayment: plan.downPayment,
        remaining: plan.remainingAmount,
        numInstallments: plan.numInstallments,
        frequency: plan.frequency,
        startDate: DateTime.now(),
      );

      return plan;
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error updating plan: $e');
      rethrow;
    }
  }

  /// Generate payment schedule via SECURITY DEFINER RPC
  /// Returns the generated payments directly from the DB function
  Future<List<InstallmentPaymentEntity>> generatePaymentSchedule({
    required String planId,
    required double downPayment,
    required double remaining,
    required int numInstallments,
    required String frequency,
    required DateTime startDate,
  }) async {
    debugPrint(
      '[InstallmentDatasource] Calling generate_installment_schedule RPC for plan $planId',
    );

    final response = await _supabase.rpc(
      'generate_installment_schedule',
      params: {
        'p_plan_id': planId,
        'p_down_payment': downPayment,
        'p_remaining': remaining,
        'p_num_installments': numInstallments,
        'p_frequency': frequency,
        'p_start_date': startDate.toIso8601String().split('T').first,
      },
    );

    final payments = (response as List)
        .map(
          (json) => InstallmentPaymentModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ).toEntity(),
        )
        .toList();

    debugPrint(
      '[InstallmentDatasource] RPC returned ${payments.length} payments',
    );
    return payments;
  }

  // =========================================================================
  // Installment Payment Operations
  // =========================================================================

  /// Fetch all payments for a plan via SECURITY DEFINER RPC
  Future<List<InstallmentPaymentEntity>> getPayments(String planId) async {
    try {
      final response = await _supabase.rpc(
        'get_plan_payments',
        params: {'p_plan_id': planId},
      );

      return (response as List)
          .map(
            (json) => InstallmentPaymentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error fetching payments: $e');
      rethrow;
    }
  }

  /// Buyer submits a payment with proof image
  Future<void> submitPayment({
    required String paymentId,
    required double amount,
    required String? proofImagePath,
  }) async {
    try {
      String? proofUrl;

      // Upload proof image if provided (unique path per attempt)
      if (proofImagePath != null) {
        proofUrl = await _uploadProofImage(proofImagePath, paymentId);
      }

      // Count existing attempts to determine attempt number
      final existing = await _supabase
          .from('installment_payment_attempts')
          .select('id')
          .eq('payment_id', paymentId);
      final attemptNumber = (existing as List).length + 1;

      // Record the attempt
      await _supabase.from('installment_payment_attempts').insert({
        'payment_id': paymentId,
        'attempt_number': attemptNumber,
        'amount': amount,
        'proof_image_url': proofUrl,
        'status': 'submitted',
        'submitted_by': _supabase.auth.currentUser?.id,
      });

      // Update the main payment row — clear stale rejection_reason
      await _supabase
          .from('installment_payments')
          .update({
            'amount': amount,
            'status': 'submitted',
            'paid_date': DateTime.now().toIso8601String(),
            'proof_image_url': proofUrl,
            'rejection_reason': null,
            'submitted_by': _supabase.auth.currentUser?.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error submitting payment: $e');
      rethrow;
    }
  }

  /// Seller confirms a payment
  Future<void> confirmPayment(String paymentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Mark the latest attempt as confirmed
      final attempts = await _supabase
          .from('installment_payment_attempts')
          .select()
          .eq('payment_id', paymentId)
          .eq('status', 'submitted')
          .order('created_at', ascending: false)
          .limit(1);

      if ((attempts as List).isNotEmpty) {
        await _supabase
            .from('installment_payment_attempts')
            .update({
              'status': 'confirmed',
              'acted_by': userId,
              'acted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', attempts.first['id']);
      }

      // Update the main payment row — clear rejection_reason
      await _supabase
          .from('installment_payments')
          .update({
            'status': 'confirmed',
            'rejection_reason': null,
            'confirmed_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error confirming payment: $e');
      rethrow;
    }
  }

  /// Seller rejects a payment
  Future<void> rejectPayment(String paymentId, String reason) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Mark the latest attempt as rejected
      final attempts = await _supabase
          .from('installment_payment_attempts')
          .select()
          .eq('payment_id', paymentId)
          .eq('status', 'submitted')
          .order('created_at', ascending: false)
          .limit(1);

      if ((attempts as List).isNotEmpty) {
        await _supabase
            .from('installment_payment_attempts')
            .update({
              'status': 'rejected',
              'rejection_reason': reason,
              'acted_by': userId,
              'acted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', attempts.first['id']);
      }

      await _supabase
          .from('installment_payments')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'confirmed_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error rejecting payment: $e');
      rethrow;
    }
  }

  /// Get payment attempts for a specific payment
  Future<List<PaymentAttemptEntity>> getPaymentAttempts(
    String paymentId,
  ) async {
    try {
      final data = await _supabase
          .from('installment_payment_attempts')
          .select()
          .eq('payment_id', paymentId)
          .order('attempt_number', ascending: true);

      return (data as List)
          .map(
            (json) => PaymentAttemptModel.fromJson(
              json as Map<String, dynamic>,
            ).toEntity(),
          )
          .toList();
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error fetching attempts: $e');
      return [];
    }
  }

  // =========================================================================
  // Image Upload
  // =========================================================================

  /// Upload proof of payment image to Supabase storage
  /// Returns a signed URL (private bucket) valid for 365 days
  /// Uses timestamp in path to preserve previous uploads
  Future<String> _uploadProofImage(String filePath, String paymentId) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final userId = _supabase.auth.currentUser?.id ?? 'unknown';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/${paymentId}_$timestamp.$ext';

    await _supabase.storage
        .from('payment-proofs')
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    // Use signed URL for private bucket (valid for 1 year)
    final signedUrl = await _supabase.storage
        .from('payment-proofs')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

    return signedUrl;
  }

  // =========================================================================
  // Realtime Streams
  // =========================================================================

  /// Stream installment plan changes
  Stream<InstallmentPlanEntity?> streamInstallmentPlan(String transactionId) {
    return _supabase
        .from('installment_plans')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', transactionId)
        .map((list) {
          if (list.isEmpty) return null;
          return InstallmentPlanModel.fromJson(list.first).toEntity();
        });
  }

  /// Stream installment payments
  Stream<List<InstallmentPaymentEntity>> streamPayments(String planId) {
    return _supabase
        .from('installment_payments')
        .stream(primaryKey: ['id'])
        .eq('installment_plan_id', planId)
        .order('payment_number')
        .map(
          (list) => list
              .map((json) => InstallmentPaymentModel.fromJson(json).toEntity())
              .toList(),
        );
  }
}
