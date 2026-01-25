import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../../browse/data/datasources/qa_supabase_datasource.dart';
import '../../../../browse/domain/entities/qa_entity.dart';

class QASection extends StatefulWidget {
  final String listingId;

  const QASection({super.key, required this.listingId});

  @override
  State<QASection> createState() => _QASectionState();
}

class _QASectionState extends State<QASection> {
  final TextEditingController _replyController = TextEditingController();
  String? _replyingToId;
  late QASupabaseDataSource _datasource;

  @override
  void initState() {
    super.initState();
    _datasource = QASupabaseDataSource(Supabase.instance.client);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _startReply(QAEntity qa) {
    setState(() {
      _replyingToId = qa.id;
      _replyController.clear();
    });
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty || _replyingToId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to reply')),
      );
      return;
    }

    try {
      await _datasource.postAnswer(
        questionId: _replyingToId!,
        sellerId: user.id,
        answer: _replyController.text.trim(),
      );
      setState(() {
        _replyingToId = null;
        _replyController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending reply: $e')));
      }
    }
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyController.clear();
    });
  }

  Future<void> _toggleLike(String questionId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to like')),
      );
      return;
    }

    try {
      await _datasource.likeQuestion(questionId: questionId, userId: user.id);
    } catch (e) {
      // Ignore if already liked or other errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<QAEntity>>(
      stream: _datasource.subscribeToQA(
        widget.listingId,
        currentUserId: currentUserId,
      ),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final unanswered = items.where((q) => !q.isAnswered).toList();
        final answered = items.where((q) => q.isAnswered).toList();

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Questions & Answers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (unanswered.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${unanswered.length} new',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 48,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No questions yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buyers will ask questions about your listing here',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Questions list
                if (unanswered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Unanswered (${unanswered.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ),
                  ...unanswered.map(
                    (qa) => _buildQuestionCard(qa, isDark, isUnanswered: true),
                  ),
                ],
                if (answered.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Answered (${answered.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ),
                  ...answered.map(
                    (qa) => _buildQuestionCard(qa, isDark, isUnanswered: false),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(
    QAEntity qa,
    bool isDark, {
    required bool isUnanswered,
  }) {
    final isReplying = _replyingToId == qa.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnanswered
            ? Colors.orange.withValues(alpha: 0.05)
            : (isDark
                  ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                  : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: isUnanswered
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
                child: Text(
                  (qa.askedBy.isNotEmpty ? qa.askedBy[0] : '?').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      qa.askedBy.isNotEmpty ? qa.askedBy : 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatTime(qa.askedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (isUnanswered)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(qa.question, style: const TextStyle(fontSize: 14)),
          if (qa.answers.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...qa.answers.asMap().entries.map((entry) {
              final index = entry.key;
              final answer = entry.value;
              final label = qa.answers.length > 1
                  ? 'Answer ${index + 1}'
                  : 'Answer';
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == qa.answers.length - 1 ? 0 : 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ColorConstants.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: ColorConstants.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$label • ${_formatTime(answer.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ColorConstants.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(answer.answer, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (isReplying) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _replyController,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelReply,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send Reply'),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        qa.isLikedByUser
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: qa.isLikedByUser
                            ? Colors.red
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      onPressed: () => _toggleLike(qa.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${qa.likesCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _startReply(qa),
                  icon: Icon(
                    isUnanswered ? Icons.reply : Icons.reply_all,
                    size: 18,
                  ),
                  label: Text(isUnanswered ? 'Reply' : 'Reply Again'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstants.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }
}
