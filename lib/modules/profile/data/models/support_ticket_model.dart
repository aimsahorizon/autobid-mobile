import '../../domain/entities/support_ticket_entity.dart';

/// Model for support ticket category
class SupportCategoryModel extends SupportCategoryEntity {
  const SupportCategoryModel({
    required super.id,
    required super.name,
    super.description,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SupportCategoryModel.fromJson(Map<String, dynamic> json) {
    return SupportCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Model for support ticket attachment
class SupportAttachmentModel extends SupportAttachmentEntity {
  const SupportAttachmentModel({
    required super.id,
    super.ticketId,
    super.messageId,
    required super.fileName,
    required super.filePath,
    required super.fileSize,
    required super.mimeType,
    required super.uploadedBy,
    required super.createdAt,
  });

  factory SupportAttachmentModel.fromJson(Map<String, dynamic> json) {
    return SupportAttachmentModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String?,
      messageId: json['message_id'] as String?,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'message_id': messageId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Model for support ticket message
class SupportMessageModel extends SupportMessageEntity {
  const SupportMessageModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.message,
    required super.isInternal,
    required super.senderName,
    required super.createdAt,
    required super.updatedAt,
    super.attachments = const [],
  });

  factory SupportMessageModel.fromJson(Map<String, dynamic> json) {
    List<SupportAttachmentModel> attachments = [];

    if (json['attachments'] != null) {
      if (json['attachments'] is List) {
        attachments = (json['attachments'] as List)
            .map((e) => SupportAttachmentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return SupportMessageModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      message: json['message'] as String,
      isInternal: json['is_internal'] as bool? ?? false,
      senderName: json['sender_name'] as String? ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      attachments: attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'is_internal': isInternal,
      'sender_name': senderName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'attachments': attachments.map((e) => (e as SupportAttachmentModel).toJson()).toList(),
    };
  }
}

/// Model for support ticket
class SupportTicketModel extends SupportTicketEntity {
  const SupportTicketModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.categoryName,
    required super.subject,
    required super.description,
    required super.status,
    required super.priority,
    super.assignedTo,
    required super.createdAt,
    required super.updatedAt,
    super.resolvedAt,
    super.closedAt,
    super.messages = const [],
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    List<SupportMessageModel> messages = [];

    if (json['messages'] != null && json['messages'] is List) {
      messages = (json['messages'] as List)
          .map((e) => SupportMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return SupportTicketModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String? ?? 'Unknown',
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: TicketStatusExtension.fromJson(json['status'] as String),
      priority: TicketPriorityExtension.fromJson(json['priority'] as String),
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'subject': subject,
      'description': description,
      'status': status.toJson(),
      'priority': priority.toJson(),
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'messages': messages.map((e) => (e as SupportMessageModel).toJson()).toList(),
    };
  }

  @override
  SupportTicketModel copyWith({
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
    return SupportTicketModel(
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
