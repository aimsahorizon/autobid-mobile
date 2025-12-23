/// Represents a customer support ticket
/// Used for tracking user issues and support conversations
class SupportTicketEntity {
  /// Unique ticket identifier
  final String id;

  /// User who created the ticket
  final String userId;

  /// Category ID
  final String categoryId;

  /// Category name
  final String categoryName;

  /// Ticket subject/title
  final String subject;

  /// Detailed description of the issue
  final String description;

  /// Current status of the ticket
  final TicketStatus status;

  /// Priority level
  final TicketPriority priority;

  /// Assigned support staff ID (if any)
  final String? assignedTo;

  /// When the ticket was created
  final DateTime createdAt;

  /// When the ticket was last updated
  final DateTime updatedAt;

  /// When the ticket was resolved (if resolved)
  final DateTime? resolvedAt;

  /// When the ticket was closed (if closed)
  final DateTime? closedAt;

  /// List of messages in the conversation
  final List<SupportMessageEntity> messages;

  const SupportTicketEntity({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.messages = const [],
  });

  /// Check if ticket is open
  bool get isOpen => status == TicketStatus.open || status == TicketStatus.inProgress;

  /// Copy with method for updates
  SupportTicketEntity copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? subject,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? closedAt,
    List<SupportMessageEntity>? messages,
  }) {
    return SupportTicketEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      messages: messages ?? this.messages,
    );
  }
}

/// Represents a message in a support ticket conversation
class SupportMessageEntity {
  /// Message ID
  final String id;

  /// Ticket ID this message belongs to
  final String ticketId;

  /// User ID who sent the message
  final String userId;

  /// Message content
  final String message;

  /// Whether this is an internal note (visible only to support staff)
  final bool isInternal;

  /// Sender name
  final String senderName;

  /// When the message was sent
  final DateTime createdAt;

  /// When the message was last updated
  final DateTime updatedAt;

  /// Optional attachment data
  final List<SupportAttachmentEntity> attachments;

  const SupportMessageEntity({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.isInternal,
    required this.senderName,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
  });

  /// Check if message is from support team
  bool get isFromSupport => isInternal;
}

/// Represents an attachment in a support ticket
class SupportAttachmentEntity {
  /// Attachment ID
  final String id;

  /// Ticket ID (if attached to ticket directly)
  final String? ticketId;

  /// Message ID (if attached to a message)
  final String? messageId;

  /// File name
  final String fileName;

  /// File path/URL
  final String filePath;

  /// File size in bytes
  final int fileSize;

  /// MIME type
  final String mimeType;

  /// User who uploaded the file
  final String uploadedBy;

  /// When the file was uploaded
  final DateTime createdAt;

  const SupportAttachmentEntity({
    required this.id,
    this.ticketId,
    this.messageId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.uploadedBy,
    required this.createdAt,
  });
}

/// Support category entity
class SupportCategoryEntity {
  /// Category ID
  final String id;

  /// Category name
  final String name;

  /// Category description
  final String? description;

  /// Whether category is active
  final bool isActive;

  /// When category was created
  final DateTime createdAt;

  /// When category was last updated
  final DateTime updatedAt;

  const SupportCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
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

/// Ticket status enum (must match database constraint)
enum TicketStatus {
  open,
  inProgress,
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
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String toJson() {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  static TicketStatus fromJson(String value) {
    switch (value) {
      case 'open':
        return TicketStatus.open;
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
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

  String toJson() {
    switch (this) {
      case TicketPriority.low:
        return 'low';
      case TicketPriority.medium:
        return 'medium';
      case TicketPriority.high:
        return 'high';
      case TicketPriority.urgent:
        return 'urgent';
    }
  }

  static TicketPriority fromJson(String value) {
    switch (value) {
      case 'low':
        return TicketPriority.low;
      case 'medium':
        return TicketPriority.medium;
      case 'high':
        return TicketPriority.high;
      case 'urgent':
        return TicketPriority.urgent;
      default:
        return TicketPriority.medium;
    }
  }
}
