import 'package:flutter/foundation.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';

/// Datasource for policy acceptance and penalty operations
class PolicyPenaltyDatasource {
  PolicyPenaltyDatasource._();
  static final instance = PolicyPenaltyDatasource._();

  /// Check if user has accepted a specific policy version for a given context.
  /// [contextId] scopes acceptance to an auction or transaction.
  /// If null, always returns false (dialog will always show).
  Future<bool> hasAcceptedPolicy({
    required String userId,
    required String policyType,
    int version = 1,
    String? contextId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'has_accepted_policy',
        params: {
          'p_user_id': userId,
          'p_policy_type': policyType,
          'p_policy_version': version,
          'p_context_id': contextId,
        },
      );
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[PolicyPenaltyDatasource] Error checking policy: $e');
      return false;
    }
  }

  /// Record policy acceptance for a given context
  Future<bool> acceptPolicy({
    required String userId,
    required String policyType,
    int version = 1,
    String? contextId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'accept_policy',
        params: {
          'p_user_id': userId,
          'p_policy_type': policyType,
          'p_policy_version': version,
          'p_context_id': contextId,
        },
      );
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('[PolicyPenaltyDatasource] Error accepting policy: $e');
      return false;
    }
  }

  /// Check if user is currently suspended
  Future<SuspensionStatus> checkSuspension(String userId) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'is_user_suspended',
        params: {'p_user_id': userId},
      );

      if (result is List && result.isNotEmpty) {
        final row = result[0] as Map<String, dynamic>;
        return SuspensionStatus(
          isSuspended: row['is_suspended'] as bool? ?? false,
          endsAt: row['suspension_ends_at'] != null
              ? DateTime.parse(row['suspension_ends_at'] as String)
              : null,
          reason: row['reason'] as String?,
          isPermanent: row['is_permanent'] as bool? ?? false,
        );
      }
      return SuspensionStatus.none();
    } catch (e) {
      debugPrint('[PolicyPenaltyDatasource] Error checking suspension: $e');
      return SuspensionStatus.none();
    }
  }

  /// Report an unresponsive user
  Future<Map<String, dynamic>?> reportUnresponsive({
    required String transactionId,
    required String reporterId,
    required String reportedUserId,
  }) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'report_unresponsive',
        params: {
          'p_transaction_id': transactionId,
          'p_reporter_id': reporterId,
          'p_reported_user_id': reportedUserId,
        },
      );
      if (result is Map<String, dynamic>) return result;
      return null;
    } catch (e) {
      debugPrint('[PolicyPenaltyDatasource] Error reporting unresponsive: $e');
      return null;
    }
  }

  /// Get user reputation stats
  Future<Map<String, dynamic>?> getUserReputation(String userId) async {
    try {
      final result = await SupabaseConfig.client.rpc(
        'get_user_reputation',
        params: {'p_user_id': userId},
      );
      if (result is Map<String, dynamic>) return result;
      return null;
    } catch (e) {
      debugPrint('[PolicyPenaltyDatasource] Error getting reputation: $e');
      return null;
    }
  }
}

/// Represents a user's current suspension status
class SuspensionStatus {
  final bool isSuspended;
  final DateTime? endsAt;
  final String? reason;
  final bool isPermanent;

  const SuspensionStatus({
    required this.isSuspended,
    this.endsAt,
    this.reason,
    this.isPermanent = false,
  });

  factory SuspensionStatus.none() => const SuspensionStatus(isSuspended: false);
}
