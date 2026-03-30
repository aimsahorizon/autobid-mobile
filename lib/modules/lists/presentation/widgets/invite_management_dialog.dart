import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/lists_controller.dart';

class InviteManagementDialog extends StatefulWidget {
  final ListsController controller;
  final String auctionId;
  final String carName;

  const InviteManagementDialog({
    super.key,
    required this.controller,
    required this.auctionId,
    required this.carName,
  });

  @override
  State<InviteManagementDialog> createState() => _InviteManagementDialogState();
}

class _InviteManagementDialogState extends State<InviteManagementDialog> {
  final _identifierController = TextEditingController();
  String _identifierType = 'username'; // 'username' or 'email'
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    widget.controller.startAuctionInvitesStream(widget.auctionId);
  }

  @override
  void dispose() {
    widget.controller.stopAuctionInvitesStream(widget.auctionId);
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;

    final success = await widget.controller.inviteUser(
      auctionId: widget.auctionId,
      identifier: identifier,
      type: _identifierType,
    );

    if (success) {
      _identifierController.clear();
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Invitation sent successfully';
          _feedbackIsError = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _feedbackMessage =
              widget.controller.errorMessage ?? 'Failed to send invite';
          _feedbackIsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Invites'),
            Text(
              widget.carName,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback banner
            if (_feedbackMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (_feedbackIsError
                          ? ColorConstants.error
                          : ColorConstants.success)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_feedbackIsError
                            ? ColorConstants.error
                            : ColorConstants.success)
                        .withAlpha(75),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackIsError
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 18,
                      color: _feedbackIsError
                          ? ColorConstants.error
                          : ColorConstants.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _feedbackIsError
                              ? ColorConstants.error
                              : ColorConstants.success,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _feedbackMessage = null),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: _feedbackIsError
                            ? ColorConstants.error
                            : ColorConstants.success,
                      ),
                    ),
                  ],
                ),
              ),

            // Invite Form
            const Text(
              'Invite New User',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      hintText: _identifierType == 'username'
                          ? 'Username'
                          : 'Email Address',
                      prefixIcon: Icon(
                        _identifierType == 'username'
                            ? Icons.person
                            : Icons.email,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _identifierType,
                    underline: const SizedBox(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    items: const [
                      DropdownMenuItem(value: 'username', child: Text('User')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                    ],
                    onChanged: (v) => setState(() => _identifierType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.controller.isInvitesLoading
                      ? null
                      : _sendInvite,
                  icon: widget.controller.isInvitesLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Send Invite'),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Invites List
            const Text(
              'Invited Users',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  if (widget.controller.isInvitesLoading &&
                      widget.controller.currentAuctionInvites.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (widget.controller.currentAuctionInvites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No one invited yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: widget.controller.currentAuctionInvites.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final invite =
                          widget.controller.currentAuctionInvites[index];
                      final identifier =
                          invite['invitee_username'] ??
                          invite['invitee_email'] ??
                          'Unknown';
                      final status = invite['status'] as String? ?? 'pending';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: ColorConstants.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            identifier[0].toUpperCase(),
                            style: TextStyle(color: ColorConstants.primary),
                          ),
                        ),
                        title: Text(identifier),
                        subtitle: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _confirmDeleteInvite(invite['id'] as String),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return ColorConstants.success;
      case 'rejected':
        return ColorConstants.error;
      default:
        return ColorConstants.warning;
    }
  }

  Future<void> _confirmDeleteInvite(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite?'),
        content: const Text(
          'This user will no longer be able to see or participate in this private auction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.controller.deleteInvite(inviteId, widget.auctionId);
    }
  }
}
