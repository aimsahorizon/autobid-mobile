import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I place a bid?',
      'answer': 'To place a bid, navigate to the auction page and enter your bid amount. Make sure you have enough tokens.',
    },
    {
      'question': 'What are tokens?',
      'answer': 'Tokens are used to place bids on auctions. You can purchase them from the profile page.',
    },
    {
      'question': 'How do I contact support?',
      'answer': 'You can contact support by creating a ticket in the Customer Support section.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqs.length,
              itemBuilder: (context, index) => _FAQItem(
                question: _faqs[index]['question']!,
                answer: _faqs[index]['answer']!,
              ),
            ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          widget.question,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          _isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
          color: ColorConstants.primary,
        ),
        onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.answer, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
