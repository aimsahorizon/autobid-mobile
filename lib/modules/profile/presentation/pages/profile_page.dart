import 'package:flutter/material.dart';
import '../../../../app/core/controllers/theme_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/settings_section.dart';

class ProfilePage extends StatefulWidget {
  final ProfileController controller;
  final ThemeController themeController;

  const ProfilePage({
    super.key,
    required this.controller,
    required this.themeController,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadProfile();
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.hasError && widget.controller.profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(widget.controller.errorMessage ?? 'Error loading profile'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.controller.loadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final profile = widget.controller.profile!;

          return RefreshIndicator(
            onRefresh: widget.controller.loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ProfileHeader(
                    coverPhotoUrl: profile.coverPhotoUrl,
                    profilePhotoUrl: profile.profilePhotoUrl,
                  ),
                  const SizedBox(height: 60),
                  ProfileInfoSection(
                    fullName: profile.fullName,
                    username: profile.username,
                    contactNumber: profile.contactNumber,
                    email: profile.email,
                  ),
                  SettingsSection(
                    themeController: widget.themeController,
                    onSignOut: _handleSignOut,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
