import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/installment_plan_model.dart';
import '../models/installment_payment_model.dart';
import '../../domain/entities/installment_plan_entity.dart';
import '../../domain/entities/installment_payment_entity.dart';

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

  /// Create a new installment plan
  Future<InstallmentPlanEntity> createInstallmentPlan({
    required String transactionId,
    required double totalAmount,
    required double downPayment,
    required int numInstallments,
    required String frequency,
    required DateTime startDate,
  }) async {
    try {
      final remaining = totalAmount - downPayment;
      final data = {
        'transaction_id': transactionId,
        'total_amount': totalAmount,
        'down_payment': downPayment,
        'remaining_amount': remaining,
        'total_paid':
            0.0, // Nothing confirmed yet — downpayment needs confirmation too
        'num_installments': numInstallments,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T').first,
      };

      final response = await _supabase
          .from('installment_plans')
          .insert(data)
          .select()
          .single();

      final plan = InstallmentPlanModel.fromJson(response).toEntity();

      // Auto-generate payment schedule (including downpayment as #0)
      await _generatePaymentSchedule(
        planId: plan.id,
        downPayment: downPayment,
        remaining: remaining,
        numInstallments: numInstallments,
        frequency: frequency,
        startDate: startDate,
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

  /// Generate payment schedule entries (including downpayment as #0)
  Future<void> _generatePaymentSchedule({
    required String planId,
    required double downPayment,
    required double remaining,
    required int numInstallments,
    required String frequency,
    required DateTime startDate,
  }) async {
    final perPayment = (remaining / numInstallments);
    final payments = <Map<String, dynamic>>[];

    // Payment #0: Down payment (3-day grace period from start)
    if (downPayment > 0) {
      final dpDueDate = startDate.add(const Duration(days: 3));
      payments.add({
        'installment_plan_id': planId,
        'payment_number': 0,
        'amount': downPayment,
        'due_date': dpDueDate.toIso8601String().split('T').first,
        'status': 'pending',
      });
    }

    // For no_schedule frequency, use a far-future sentinel date
    final isNoSchedule = frequency == 'no_schedule';

    for (int i = 0; i < numInstallments; i++) {
      DateTime dueDate;
      if (isNoSchedule) {
        // Sentinel date indicating no due date
        dueDate = DateTime(9999, 12, 31);
      } else {
        switch (frequency) {
          case 'weekly':
            dueDate = startDate.add(Duration(days: 7 * (i + 1)));
            break;
          case 'bi-weekly':
            dueDate = startDate.add(Duration(days: 14 * (i + 1)));
            break;
          case 'monthly':
          default:
            dueDate = DateTime(
              startDate.year,
              startDate.month + (i + 1),
              startDate.day,
            );
            break;
        }
      }

      // Last payment gets any rounding remainder
      final amount = i == numInstallments - 1
          ? remaining - (perPayment.floorToDouble() * (numInstallments - 1))
          : perPayment.floorToDouble();

      payments.add({
        'installment_plan_id': planId,
        'payment_number': i + 1,
        'amount': amount,
        'due_date': dueDate.toIso8601String().split('T').first,
        'status': 'pending',
      });
    }

    await _supabase.from('installment_payments').insert(payments);
  }

  // =========================================================================
  // Installment Payment Operations
  // =========================================================================

  /// Fetch all payments for a plan
  Future<List<InstallmentPaymentEntity>> getPayments(String planId) async {
    try {
      final response = await _supabase
          .from('installment_payments')
          .select()
          .eq('installment_plan_id', planId)
          .order('payment_number');

      return (response as List)
          .map((json) => InstallmentPaymentModel.fromJson(json).toEntity())
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

      // Upload proof image if provided
      if (proofImagePath != null) {
        proofUrl = await _uploadProofImage(proofImagePath, paymentId);
      }

      await _supabase
          .from('installment_payments')
          .update({
            'amount': amount,
            'status': 'submitted',
            'paid_date': DateTime.now().toIso8601String(),
            'proof_image_url': proofUrl,
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
      await _supabase
          .from('installment_payments')
          .update({
            'status': 'confirmed',
            'confirmed_by': _supabase.auth.currentUser?.id,
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
      await _supabase
          .from('installment_payments')
          .update({
            'status': 'rejected',
            'rejection_reason': reason,
            'confirmed_by': _supabase.auth.currentUser?.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (e) {
      debugPrint('[InstallmentDatasource] Error rejecting payment: $e');
      rethrow;
    }
  }

  // =========================================================================
  // Image Upload
  // =========================================================================

  /// Upload proof of payment image to Supabase storage
  /// Returns a signed URL (private bucket) valid for 365 days
  Future<String> _uploadProofImage(String filePath, String paymentId) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final userId = _supabase.auth.currentUser?.id ?? 'unknown';
    final storagePath = '$userId/$paymentId.$ext';

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
