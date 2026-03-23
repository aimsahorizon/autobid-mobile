/// Policy types and their current versions.
/// Bump the version when policies change to re-prompt acceptance.
class PolicyConstants {
  PolicyConstants._();

  // Policy type identifiers
  static const String biddingRules = 'bidding_rules';
  static const String listingRules = 'listing_rules';
  static const String transactionRules = 'transaction_rules';

  // Current policy versions — increment to re-prompt users
  static const int biddingRulesVersion = 1;
  static const int listingRulesVersion = 1;
  static const int transactionRulesVersion = 1;

  /// Bidding rules shown to buyers before first bid
  static const List<String> biddingPolicies = [
    'By bidding, you commit to purchasing the vehicle if you win the auction.',
    'If you win and fail to pay the required deposit within 48 hours, the win is forfeited and your account may be suspended.',
    'Backing out after paying a deposit results in partial or full deposit deduction depending on the transaction stage.',
    'Repeated cancellations lead to escalating suspensions: 3 days → 7 days → 30 days → 90 days → permanent ban (12-month rolling window).',
    'Your bidding rate and transaction history are visible to sellers as part of your reputation profile.',
    'All deposits are refundable in full upon successful transaction completion or mutual cancellation.',
  ];

  /// Listing rules shown to sellers before submission
  static const List<String> listingPolicies = [
    'By listing your vehicle, you commit to selling it to the winning bidder if the reserve price is met.',
    'You must proceed to transaction within 24 hours after the auction ends if the reserve is met. Failure results in account suspension.',
    'You must pay a refundable deposit (equal to the buyer\'s deposit) when starting the transaction as a security guarantee.',
    'Cancelling a transaction results in deposit deduction and account suspension. The buyer\'s deposit will be fully refunded.',
    'Repeated cancellations lead to escalating suspensions and relist restrictions.',
    'Your transaction success rate is visible to buyers as part of your reputation profile.',
    'All deposits are refundable in full upon successful transaction completion or mutual cancellation.',
  ];

  /// Transaction rules shown to both parties before entering pre-transaction
  static const List<String> transactionPolicies = [
    'Both buyer and seller must pay a refundable deposit before proceeding.',
    'Deposits are returned in full upon successful transaction completion or mutual cancellation.',
    'If you cancel unilaterally, penalties will be imposed based on the transaction stage:',
    '  • Before agreement forms: 25% deposit deduction + suspension',
    '  • After agreement forms: 50% deposit deduction + suspension',
    '  • During delivery: 75% deposit deduction + suspension',
    'Mutual cancellation (both parties agree) incurs no penalties and full deposit refund.',
    'If the other party is unresponsive for 48 hours, you may report them. They will have 24 hours to respond or the transaction will be auto-cancelled with penalties on the unresponsive party.',
    'If neither party takes action for 7 days, the transaction is auto-cancelled and both accounts are suspended.',
    'Suspension escalation: 1st offense: 3 days, 2nd: 7 days, 3rd: 30 days, 4th: 90 days, 5th+: permanent ban (12-month rolling window).',
    'All penalties are permanently recorded on your reputation profile.',
  ];
}
