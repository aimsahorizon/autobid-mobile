import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/core/controllers/theme_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/settings_section.dart';
import '../widgets/account_settings_section.dart';
import '../widgets/support_section.dart';
import 'update_email_page.dart';
import 'update_phone_page.dart';
import 'customer_support_page.dart';
import 'faq_page.dart';
import 'legal_page.dart';

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
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    widget.controller.loadProfile();
  }

  void _handleCoverPhotoTap() {
    _showImageSourceDialog(isCover: true);
  }

  void _handleProfilePhotoTap() {
    _showImageSourceDialog(isCover: false);
  }

  void _showImageSourceDialog({required bool isCover}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCover ? 'Update Cover Photo' : 'Update Profile Photo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isCover);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isCover);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isCover) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: isCover ? 1920 : 800,
        maxHeight: isCover ? 1080 : 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // TODO: Upload to Supabase Storage:
        // final bytes = await image.readAsBytes();
        // final path = '${userId}/${isCover ? 'cover' : 'profile'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        // await supabase.storage.from('profiles').uploadBinary(path, bytes);
        // final url = supabase.storage.from('profiles').getPublicUrl(path);
        // await widget.controller.updatePhoto(url, isCover);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isCover ? 'Cover' : 'Profile'} photo selected: ${image.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _navigateToUpdateEmail() {
    final profile = widget.controller.profile;
    if (profile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateEmailPage(
          currentEmail: profile.email,
          currentPhone: profile.contactNumber,
        ),
      ),
    );
  }

  void _navigateToUpdatePhone() {
    final profile = widget.controller.profile;
    if (profile == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdatePhonePage(
          currentEmail: profile.email,
          currentPhone: profile.contactNumber,
        ),
      ),
    );
  }

  void _navigateToCustomerSupport() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerSupportPage()));
  }

  void _navigateToFAQ() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage()));
  }

  void _navigateToTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LegalPage(title: 'Terms & Conditions', type: 'terms')),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LegalPage(title: 'Privacy Policy', type: 'privacy')),
    );
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await widget.controller.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
                    onCoverPhotoTap: _handleCoverPhotoTap,
                    onProfilePhotoTap: _handleProfilePhotoTap,
                  ),
                  const SizedBox(height: 60),
                  ProfileInfoSection(
                    fullName: profile.fullName,
                    username: profile.username,
                    contactNumber: profile.contactNumber,
                    email: profile.email,
                  ),
                  const SizedBox(height: 16),
                  AccountSettingsSection(
                    email: profile.email,
                    phone: profile.contactNumber,
                    onUpdateEmail: _navigateToUpdateEmail,
                    onUpdatePhone: _navigateToUpdatePhone,
                  ),
                  const SizedBox(height: 16),
                  SupportSection(
                    onCustomerSupport: _navigateToCustomerSupport,
                    onFAQ: _navigateToFAQ,
                    onTermsConditions: _navigateToTerms,
                    onPrivacyPolicy: _navigateToPrivacy,
                  ),
                  const SizedBox(height: 16),
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
