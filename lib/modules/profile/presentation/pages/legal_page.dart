import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';

class LegalPage extends StatelessWidget {
  final String title;
  final String type; // 'terms' or 'privacy'

  const LegalPage({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: type == 'terms' ? const _TermsContent() : const _PrivacyContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegalSection(
          title: '1. Acceptance of Terms',
          content: 'By accessing and using AutoBid, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.',
        ),
        _LegalSection(
          title: '2. User Registration',
          content: 'To use our auction services, you must create an account with accurate information. You are responsible for maintaining the confidentiality of your account credentials.',
        ),
        _LegalSection(
          title: '3. Auction Rules',
          content: 'All bids are binding. Once you place a bid, you are committed to complete the purchase if you win. Deposits are required to participate in auctions and are refundable if you do not win.',
        ),
        _LegalSection(
          title: '4. Seller Obligations',
          content: 'Sellers must provide accurate descriptions and photos of vehicles. Misrepresentation may result in account suspension and legal action.',
        ),
        _LegalSection(
          title: '5. Fees and Payments',
          content: 'Buyers pay no fees. Sellers pay a 3% success fee upon successful sale. All payments are processed through our secure payment partners.',
        ),
        _LegalSection(
          title: '6. Dispute Resolution',
          content: 'Any disputes between buyers and sellers will be mediated by AutoBid. Our decision is final. Major disputes may be referred to appropriate legal authorities.',
        ),
        _LegalSection(
          title: '7. Limitation of Liability',
          content: 'AutoBid serves as a platform connecting buyers and sellers. We are not responsible for the condition of vehicles or actions of users. Transactions are between users.',
        ),
        _LegalSection(
          title: '8. Termination',
          content: 'We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activity, or harm other users.',
        ),
        const SizedBox(height: 16),
        Text(
          'Last updated: January 2025',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegalSection(
          title: '1. Information We Collect',
          content: 'We collect information you provide (name, email, phone, ID documents) and automatically collected data (device info, usage patterns, location).',
        ),
        _LegalSection(
          title: '2. How We Use Your Information',
          content: 'Your information is used to: provide our services, verify identity, process transactions, communicate with you, and improve our platform.',
        ),
        _LegalSection(
          title: '3. Information Sharing',
          content: 'We share information with: other users (for transactions), payment processors, identity verification services, and when required by law.',
        ),
        _LegalSection(
          title: '4. Data Security',
          content: 'We implement industry-standard security measures including encryption, secure servers, and regular security audits to protect your data.',
        ),
        _LegalSection(
          title: '5. Your Rights',
          content: 'You have the right to: access your data, correct inaccuracies, request deletion, opt-out of marketing, and export your data.',
        ),
        _LegalSection(
          title: '6. Cookies and Tracking',
          content: 'We use cookies and similar technologies to improve user experience, analyze usage, and personalize content. You can manage cookie preferences in your browser.',
        ),
        _LegalSection(
          title: '7. Data Retention',
          content: 'We retain your data for as long as your account is active and as required by law. Transaction records are kept for 7 years for legal compliance.',
        ),
        _LegalSection(
          title: '8. Contact Us',
          content: 'For privacy concerns, contact our Data Protection Officer at privacy@autobid.com or through the Customer Support section.',
        ),
        const SizedBox(height: 16),
        Text(
          'Last updated: January 2025',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String content;

  const _LegalSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
