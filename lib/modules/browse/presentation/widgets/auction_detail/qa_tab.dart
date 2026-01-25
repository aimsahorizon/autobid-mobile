import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/qa_entity.dart';

class QATab extends StatefulWidget {
  final List<QAEntity> questions;
  final bool isLoading;
  final Function(String category, String question) onAskQuestion;
  final Function(String questionId) onToggleLike;

  const QATab({
    super.key,
    required this.questions,
    required this.onAskQuestion,
    required this.onToggleLike,
    this.isLoading = false,
  });

  @override
  State<QATab> createState() => _QATabState();
}

class _QATabState extends State<QATab> {
  String _selectedCategory = QACategory.all;

  List<QAEntity> get _filteredQuestions {
    if (_selectedCategory == QACategory.all) return widget.questions;
    return widget.questions.where((q) => q.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryChips(
          selectedCategory: _selectedCategory,
          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
        ),
        _AskQuestionButton(onTap: () => _showAskQuestionDialog(context)),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredQuestions.isEmpty
                  ? const _EmptyQuestions()
                  : _QuestionsList(
                      questions: _filteredQuestions,
                      onToggleLike: widget.onToggleLike,
                    ),
        ),
      ],
    );
  }

  void _showAskQuestionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AskQuestionSheet(
        onSubmit: widget.onAskQuestion,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const _CategoryChips({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: QACategory.categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(QACategory.formatForDisplay(category)),
              onSelected: (_) => onCategorySelected(category),
              selectedColor: ColorConstants.primary.withValues(alpha: 0.2),
              checkmarkColor: ColorConstants.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AskQuestionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AskQuestionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.help_outline),
          label: const Text('Ask a Question'),
        ),
      ),
    );
  }
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: ColorConstants.textSecondaryLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No questions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ColorConstants.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to ask!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _QuestionsList extends StatelessWidget {
  final List<QAEntity> questions;
  final Function(String) onToggleLike;

  const _QuestionsList({
    required this.questions,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _QuestionCard(
        question: questions[index],
        onToggleLike: () => onToggleLike(questions[index].id),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QAEntity question;
  final VoidCallback onToggleLike;

  const _QuestionCard({
    required this.question,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryBadge(category: question.category),
              const Spacer(),
              _StatusBadge(isAnswered: question.isAnswered),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Asked by ${question.askedBy} • ${_formatTime(question.askedAt)}',
            style: theme.textTheme.bodySmall,
          ),
          if (question.isAnswered) ...[
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.store,
                  size: 20,
                  color: ColorConstants.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller Response',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.answer!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: onToggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: question.isLikedByUser
                        ? ColorConstants.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: question.isLikedByUser
                          ? ColorConstants.primary
                          : (isDark ? ColorConstants.borderDark : ColorConstants.borderLight),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        question.isLikedByUser ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 16,
                        color: question.isLikedByUser
                            ? ColorConstants.primary
                            : ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${question.likesCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: question.isLikedByUser
                              ? ColorConstants.primary
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        QACategory.formatForDisplay(category),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAnswered;

  const _StatusBadge({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAnswered
            ? ColorConstants.success.withValues(alpha: 0.1)
            : ColorConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnswered ? Icons.check_circle : Icons.schedule,
            size: 12,
            color: isAnswered ? ColorConstants.success : ColorConstants.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isAnswered ? 'Answered' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isAnswered ? ColorConstants.success : ColorConstants.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _AskQuestionSheet extends StatefulWidget {
  final Function(String category, String question) onSubmit;

  const _AskQuestionSheet({required this.onSubmit});

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  String _selectedCategory = QACategory.general;
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _selectSuggested(String category, String question) {
    setState(() {
      _selectedCategory = category;
      _questionController.text = question;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask a Question',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text('Category', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: QACategory.categories
                  .where((c) => c != QACategory.all)
                  .map((cat) => ChoiceChip(
                        label: Text(QACategory.formatForDisplay(cat)),
                        selected: _selectedCategory == cat,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Common Questions', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: SuggestedQuestions.questions
                    .map((q) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              q['question']!.length > 25
                                  ? '${q['question']!.substring(0, 25)}...'
                                  : q['question']!,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _selectSuggested(
                              q['category']!,
                              q['question']!,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your Question',
                hintText: 'Type your question here...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_questionController.text.isNotEmpty) {
                    widget.onSubmit(_selectedCategory, _questionController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit Question'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
