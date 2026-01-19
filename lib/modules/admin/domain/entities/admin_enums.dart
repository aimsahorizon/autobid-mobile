/// Enums for Admin module to provide clarity for Next.js migration.
/// These match the 'status_name' values in the 'auction_statuses' table.
enum AdminListingStatus {
  draft('draft'),
  pendingApproval('pending_approval'),
  scheduled('scheduled'),
  live('live'),
  ended('ended'),
  cancelled('cancelled'),
  inTransaction('in_transaction'),
  sold('sold'),
  dealFailed('deal_failed');

  final String dbValue;
  const AdminListingStatus(this.dbValue);

  /// Helper to convert DB string to Enum
  static AdminListingStatus fromString(String value) {
    return AdminListingStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => AdminListingStatus.pendingApproval,
    );
  }
}

/// Enums for User status in Admin view
enum AdminUserStatus {
  active,
  suspended,
  pendingKyc;
}
