/// Transaction status representing post-auction states
/// Separate from ListingStatus to maintain clear separation of concerns
enum TransactionStatus {
  /// Active negotiation between buyer and seller
  inTransaction,

  /// Transaction completed successfully
  sold,

  /// Transaction cancelled during negotiation phase
  dealFailed,
}

/// Extension to get display properties for each transaction status
extension TransactionStatusExtension on TransactionStatus {
  /// Get human-readable label for display
  String get label {
    switch (this) {
      case TransactionStatus.inTransaction:
        return 'In Transaction';
      case TransactionStatus.sold:
        return 'Completed';
      case TransactionStatus.dealFailed:
        return 'Failed';
    }
  }

  /// Get short tab label for bottom navigation/tabs
  String get tabLabel {
    switch (this) {
      case TransactionStatus.inTransaction:
        return 'Active';
      case TransactionStatus.sold:
        return 'Completed';
      case TransactionStatus.dealFailed:
        return 'Failed';
    }
  }

  /// Get database status name for queries
  String get databaseStatus {
    switch (this) {
      case TransactionStatus.inTransaction:
        return 'in_transaction';
      case TransactionStatus.sold:
        return 'sold';
      case TransactionStatus.dealFailed:
        return 'deal_failed';
    }
  }

  /// Get status color for UI
  /// Returns Color constant name (to be used with ColorConstants)
  String get colorName {
    switch (this) {
      case TransactionStatus.inTransaction:
        return 'primary'; // Blue - active state
      case TransactionStatus.sold:
        return 'success'; // Green - completed
      case TransactionStatus.dealFailed:
        return 'error'; // Red - failed
    }
  }

  /// Get icon for status display
  /// Returns IconData constant name
  String get iconName {
    switch (this) {
      case TransactionStatus.inTransaction:
        return 'handshake_outlined';
      case TransactionStatus.sold:
        return 'check_circle';
      case TransactionStatus.dealFailed:
        return 'cancel_outlined';
    }
  }
}

/// Parse database status string to TransactionStatus enum
TransactionStatus parseTransactionStatus(String status) {
  switch (status.toLowerCase()) {
    case 'in_transaction':
      return TransactionStatus.inTransaction;
    case 'sold':
      return TransactionStatus.sold;
    case 'deal_failed':
      return TransactionStatus.dealFailed;
    default:
      throw ArgumentError('Invalid transaction status: $status');
  }
}
