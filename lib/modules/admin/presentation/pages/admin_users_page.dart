import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/admin_controller.dart';

/// Admin page for managing users
class AdminUsersPage extends StatefulWidget {
  final AdminController controller;

  const AdminUsersPage({
    super.key,
    required this.controller,
  });

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.controller.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
                const SizedBox(height: 16),
                const Text(
                  'Error loading users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.controller.error!),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => widget.controller.loadUsers(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = widget.controller.users;

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: ColorConstants.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => widget.controller.loadUsers(),
          child: Column(
            children: [
              // Header with user count
              Container(
                padding: const EdgeInsets.all(16),
                color: ColorConstants.surfaceVariantLight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Users: ${users.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // TODO: Implement search functionality
                      },
                    ),
                  ],
                ),
              ),

              // Users List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
                          child: Text(
                            user['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              color: ColorConstants.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user['full_name']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(user['email']?.toString() ?? ''),
                            if (user['phone_number'] != null)
                              Text(user['phone_number'].toString()),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildVerificationBadge(
                                  'Email',
                                  user['is_email_verified'] == true,
                                ),
                                const SizedBox(width: 8),
                                _buildVerificationBadge(
                                  'Phone',
                                  user['is_phone_verified'] == true,
                                ),
                                const SizedBox(width: 8),
                                _buildVerificationBadge(
                                  'KYC',
                                  user['kyc_status']?.toString() == 'verified',
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'view') {
                              _showUserDetails(user);
                            } else if (value == 'suspend') {
                              _confirmSuspendUser(user);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'suspend',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 20),
                                  SizedBox(width: 8),
                                  Text('Suspend User'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVerificationBadge(String label, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isVerified
            ? ColorConstants.success.withValues(alpha: 0.1)
            : ColorConstants.textSecondaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isVerified ? ColorConstants.success : ColorConstants.textSecondaryLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            size: 10,
            color: isVerified ? ColorConstants.success : ColorConstants.textSecondaryLight,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: isVerified ? ColorConstants.success : ColorConstants.textSecondaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', user['full_name']?.toString() ?? 'N/A'),
              _buildDetailRow('Email', user['email']?.toString() ?? 'N/A'),
              _buildDetailRow('Phone', user['phone_number']?.toString() ?? 'N/A'),
              _buildDetailRow('KYC Status', user['kyc_status']?.toString() ?? 'pending'),
              _buildDetailRow(
                'Created',
                user['created_at'] != null
                    ? DateTime.parse(user['created_at'].toString()).toString().substring(0, 10)
                    : 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _confirmSuspendUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend User'),
        content: Text(
          'Are you sure you want to suspend ${user['full_name']}? This action can be reversed later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement suspend user functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suspend user functionality coming soon'),
                  backgroundColor: ColorConstants.warning,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}
