import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/buyer_transaction_controller.dart';

class TransactionChatTab extends StatefulWidget {
  final BuyerTransactionController controller;

  const TransactionChatTab({
    super.key,
    required this.controller,
  });

  @override
  State<TransactionChatTab> createState() => _TransactionChatTabState();
}

class _TransactionChatTabState extends State<TransactionChatTab> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    widget.controller.sendMessage('buyer_current', 'You', message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final messages = widget.controller.chatMessages;

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == 'buyer_current';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ColorConstants.textSecondaryLight
                                .withValues(alpha: 0.2),
                            child: Text(
                              message.senderName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.senderName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? ColorConstants.textSecondaryDark
                                      : ColorConstants.textSecondaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? ColorConstants.primary
                                      : (isDark
                                          ? ColorConstants.surfaceDark
                                          : ColorConstants.backgroundSecondaryLight),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  message.message,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isMe ? Colors.white : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(message.timestamp),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? ColorConstants.textSecondaryDark
                                      : ColorConstants.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: ColorConstants.primary,
                            child: const Text(
                              'Y',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? ColorConstants.backgroundDark
                        : ColorConstants.backgroundSecondaryLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
