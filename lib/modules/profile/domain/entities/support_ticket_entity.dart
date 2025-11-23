/// Represents a customer support ticket
/// Used for tracking user issues and support conversations
class SupportTicketEntity {
  /// Unique ticket identifier
  final String id;

  /// Ticket subject/title
  final String subject;

  /// Category of the issue
  final SupportCategory category;

  /// Current status of the ticket
  final TicketStatus status;

  /// Priority level
  final TicketPriority priority;

  /// When the ticket was created
  final DateTime createdAt;

  /// When the ticket was last updated
  final DateTime updatedAt;

  /// List of messages in the conversation
  final List<SupportMessageEntity> messages;

  const SupportTicketEntity({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  /// Check if ticket is open
  bool get isOpen => status == TicketStatus.open || status == TicketStatus.inProgress;
}

/// Represents a message in a support ticket conversation
class SupportMessageEntity {
  /// Message ID
  final String id;

  /// Message content
  final String message;

  /// Whether this message is from support team
  final bool isFromSupport;

  /// Sender name
  final String senderName;

  /// When the message was sent
  final DateTime timestamp;

  /// Optional attachment URLs
  final List<String> attachments;

  const SupportMessageEntity({
    required this.id,
    required this.message,
    required this.isFromSupport,
    required this.senderName,
    required this.timestamp,
    this.attachments = const [],
  });
}

/// Support ticket categories
enum SupportCategory {
  general,
  billing,
  technical,
  account,
  auction,
  listing,
  payment,
  other,
}

/// Extension for category display names
extension SupportCategoryExtension on SupportCategory {
  String get label {
    switch (this) {
      case SupportCategory.general:
        return 'General Inquiry';
      case SupportCategory.billing:
        return 'Billing & Payments';
      case SupportCategory.technical:
        return 'Technical Issue';
      case SupportCategory.account:
        return 'Account & Profile';
      case SupportCategory.auction:
        return 'Auction Related';
      case SupportCategory.listing:
        return 'Listing Help';
      case SupportCategory.payment:
        return 'Payment Issues';
      case SupportCategory.other:
        return 'Other';
    }
  }
}

/// Ticket status enum
enum TicketStatus {
  open,
  inProgress,
  waitingOnCustomer,
  resolved,
  closed,
}

/// Extension for status display
extension TicketStatusExtension on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.waitingOnCustomer:
        return 'Awaiting Reply';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

/// Ticket priority enum
enum TicketPriority {
  low,
  medium,
  high,
  urgent,
}

/// Extension for priority display
extension TicketPriorityExtension on TicketPriority {
  String get label {
    switch (this) {
      case TicketPriority.low:
        return 'Low';
      case TicketPriority.medium:
        return 'Medium';
      case TicketPriority.high:
        return 'High';
      case TicketPriority.urgent:
        return 'Urgent';
    }
  }
}
