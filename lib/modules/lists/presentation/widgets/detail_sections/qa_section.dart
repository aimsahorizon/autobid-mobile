import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../../browse/domain/entities/qa_entity.dart';

class QASection extends StatefulWidget {
  final String listingId;

  const QASection({super.key, required this.listingId});

  @override
  State<QASection> createState() => _QASectionState();
}

class _QASectionState extends State<QASection> {
  final List<QAEntity> _mockQuestions = [
    QAEntity(
      id: '1',
      auctionId: '',
      category: 'General',
      question: 'Is the car still under factory warranty?',
      askedBy: 'John Doe',
      askedAt: DateTime.now().subtract(const Duration(hours: 5)),
      answer: null,
      answeredAt: null,
    ),
    QAEntity(
      id: '2',
      auctionId: '',
      category: 'Mechanical',
      question: 'Has the timing belt been replaced?',
      askedBy: 'Jane Smith',
      askedAt: DateTime.now().subtract(const Duration(days: 1)),
      answer: 'Yes, timing belt was replaced at 80,000 km with complete service records.',
      answeredAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    QAEntity(
      id: '3',
      auctionId: '',
      category: 'General',
      question: 'Can I schedule a viewing in Quezon City?',
      askedBy: 'Mike Johnson',
      askedAt: DateTime.now().subtract(const Duration(days: 2)),
      answer: null,
      answeredAt: null,
    ),
  ];

  final TextEditingController _replyController = TextEditingController();
  String? _replyingToId;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _startReply(String questionId) {
    setState(() {
      _replyingToId = questionId;
      _replyController.clear();
    });
  }

  void _submitReply() {
    if (_replyController.text.trim().isEmpty) return;

    // TODO: Implement backend submission
    setState(() {
      final index = _mockQuestions.indexWhere((q) => q.id == _replyingToId);
      if (index != -1) {
        _mockQuestions[index] = QAEntity(
          id: _mockQuestions[index].id,
          auctionId: _mockQuestions[index].auctionId,
          category: _mockQuestions[index].category,
          askedBy: _mockQuestions[index].askedBy,
          question: _mockQuestions[index].question,
          askedAt: _mockQuestions[index].askedAt,
          answer: _replyController.text.trim(),
          answeredAt: DateTime.now(),
        );
      }
      _replyingToId = null;
      _replyController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply sent successfully')),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingToId = null;
      _replyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final unanswered = _mockQuestions.where((q) => q.answer == null).toList();
    final answered = _mockQuestions.where((q) => q.answer != null).toList();

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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (unanswered.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (_mockQuestions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No questions yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else ...[
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
              ...unanswered.map((qa) => _buildQuestionCard(qa, isDark, isUnanswered: true)),
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
              ...answered.map((qa) => _buildQuestionCard(qa, isDark, isUnanswered: false)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QAEntity qa, bool isDark, {required bool isUnanswered}) {
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
                  qa.askedBy[0].toUpperCase(),
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
                      qa.askedBy,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(
            qa.question,
            style: const TextStyle(fontSize: 14),
          ),
          if (qa.answer != null) ...[
            const SizedBox(height: 12),
            Container(
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
                        'Your answer • ${_formatTime(qa.answeredAt!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qa.answer!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
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
          ] else if (isUnanswered) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _startReply(qa.id),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply'),
                style: TextButton.styleFrom(
                  foregroundColor: ColorConstants.primary,
                ),
              ),
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
