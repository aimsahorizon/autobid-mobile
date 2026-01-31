import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../browse/data/datasources/invites_supabase_datasource.dart';

class InviteUserDialog extends StatefulWidget {
  final String auctionId;
  final String auctionTitle;

  const InviteUserDialog({
    super.key,
    required this.auctionId,
    required this.auctionTitle,
  });

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _identifierController = TextEditingController();
  late final InvitesSupabaseDatasource _invitesDataSource;
  String _selectedType = 'username'; // 'username' or 'email'
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invitesDataSource = InvitesSupabaseDatasource(
      supabase: Supabase.instance.client,
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username or email');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _invitesDataSource.inviteUser(
        auctionId: widget.auctionId,
        identifier: identifier,
        type: _selectedType,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invite sent to $identifier'),
          backgroundColor: ColorConstants.success,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send invite: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_add, color: ColorConstants.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Invite User')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite a user to this private auction',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.info.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ColorConstants.info.withAlpha((0.3 * 255).toInt()),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: ColorConstants.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.auctionTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorConstants.info,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Invite by',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Username'),
                    selected: _selectedType == 'username',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = 'username');
                      }
                    },
                    selectedColor: ColorConstants.primary,
                    labelStyle: TextStyle(
                      color: _selectedType == 'username'
                          ? Colors.white
                          : ColorConstants.textPrimaryLight,
                      fontWeight: _selectedType == 'username'
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Email'),
                    selected: _selectedType == 'email',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = 'email');
                      }
                    },
                    selectedColor: ColorConstants.primary,
                    labelStyle: TextStyle(
                      color: _selectedType == 'email'
                          ? Colors.white
                          : ColorConstants.textPrimaryLight,
                      fontWeight: _selectedType == 'email'
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: _selectedType == 'username'
                    ? 'Username'
                    : 'Email Address',
                hintText: _selectedType == 'username'
                    ? 'e.g., johndoe'
                    : 'e.g., user@example.com',
                prefixIcon: Icon(
                  _selectedType == 'username' ? Icons.person : Icons.email,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: _selectedType == 'email'
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              enabled: !_isProcessing,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstants.error.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConstants.error.withAlpha((0.3 * 255).toInt()),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: ColorConstants.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isProcessing ? null : _sendInvite,
          icon: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isProcessing ? 'Sending...' : 'Send Invite'),
        ),
      ],
    );
  }
}
