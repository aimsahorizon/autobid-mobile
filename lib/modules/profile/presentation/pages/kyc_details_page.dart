import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../data/datasources/profile_supabase_datasource.dart';

class KycDetailsPage extends StatefulWidget {
  const KycDetailsPage({super.key});

  @override
  State<KycDetailsPage> createState() => _KycDetailsPageState();
}

class _KycDetailsPageState extends State<KycDetailsPage> {
  late final ProfileSupabaseDataSource _datasource;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _datasource = GetIt.instance<ProfileSupabaseDataSource>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _datasource.getMyKycData();
      if (mounted) setState(() => _data = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: ColorConstants.error,
                  ),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _data == null
          ? const Center(child: Text('No KYC data found.'))
          : _buildContent(theme, isDark),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    final kyc = _data!['kyc'] as Map<String, dynamic>?;
    final address = _data!['address'] as Map<String, dynamic>? ?? {};
    final kycStatus = _data!['kyc_status'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status Banner ──────────────────────────────────────────
        _StatusBanner(status: kycStatus),
        const SizedBox(height: 20),

        // ── Personal Information ───────────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: 'Personal Information',
          icon: Icons.person_outline,
          children: [
            _InfoRow('First Name', _data!['first_name']),
            _InfoRow('Middle Name', _data!['middle_name']),
            _InfoRow('Last Name', _data!['last_name']),
            _InfoRow('Date of Birth', _formatDate(_data!['date_of_birth'])),
            _InfoRow('Sex', _capitalize(_data!['sex'])),
            _InfoRow('Phone', _data!['phone_number']),
          ],
        ),
        const SizedBox(height: 16),

        // ── Address ────────────────────────────────────────────────
        _SectionCard(
          isDark: isDark,
          title: 'Address',
          icon: Icons.location_on_outlined,
          children: [
            _InfoRow('Region', address['region']),
            _InfoRow('Province', address['province']),
            _InfoRow('City / Municipality', address['city']),
            _InfoRow('Barangay', address['barangay']),
            _InfoRow('Street Address', address['street_address']),
            _InfoRow('Zip Code', address['zipcode']),
          ],
        ),
        const SizedBox(height: 16),

        // ── Documents ──────────────────────────────────────────────
        if (kyc != null) ...[
          _SectionCard(
            isDark: isDark,
            title: 'KYC Documents',
            icon: Icons.badge_outlined,
            children: [
              _InfoRow('National ID No.', kyc['national_id_number']),
              _InfoRow(
                'Secondary ID Type',
                _formatIdType(kyc['secondary_gov_id_type']),
              ),
              _InfoRow('Secondary ID No.', kyc['secondary_gov_id_number']),
              _InfoRow(
                'Proof of Address Type',
                _formatIdType(kyc['proof_of_address_type']),
              ),
              if (kyc['submitted_at'] != null)
                _InfoRow('Submitted', _formatDateTime(kyc['submitted_at'])),
              if (kyc['reviewed_at'] != null)
                _InfoRow('Reviewed', _formatDateTime(kyc['reviewed_at'])),
              if (kyc['rejection_reason'] != null) ...[
                const Divider(height: 24),
                _InfoRow(
                  'Rejection Reason',
                  kyc['rejection_reason'],
                  valueColor: ColorConstants.error,
                ),
              ],
              if (kyc['admin_notes'] != null &&
                  (kyc['admin_notes'] as String).isNotEmpty)
                _InfoRow('Admin Notes', kyc['admin_notes']),
            ],
          ),
          const SizedBox(height: 16),

          // ── Photo Documents ────────────────────────────────────────
          _PhotoSectionCard(
            isDark: isDark,
            title: 'Document Photos',
            photos: [
              _PhotoEntry('National ID (Front)', kyc['national_id_front_url']),
              _PhotoEntry('National ID (Back)', kyc['national_id_back_url']),
              _PhotoEntry(
                'Secondary ID (Front)',
                kyc['secondary_gov_id_front_url'],
              ),
              _PhotoEntry(
                'Secondary ID (Back)',
                kyc['secondary_gov_id_back_url'],
              ),
              _PhotoEntry('Proof of Address', kyc['proof_of_address_url']),
              _PhotoEntry('Selfie with ID', kyc['selfie_with_id_url']),
            ],
            onPhotoTap: (url, label) => _showFullPhoto(url, label),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  void _showFullPhoto(String url, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullPhotoViewer(url: url, label: label),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _capitalize(dynamic value) {
    if (value == null) return '—';
    final s = value.toString();
    if (s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatIdType(dynamic value) {
    if (value == null) return '—';
    return value
        .toString()
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String? status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cfg.color.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(cfg.icon, color: cfg.color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.label,
                  style: TextStyle(
                    color: cfg.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cfg.description,
                  style: TextStyle(
                    color: cfg.color.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(String? status) {
    switch (status) {
      case 'approved':
        return _StatusConfig(
          color: ColorConstants.success,
          icon: Icons.verified_user,
          label: 'Verified',
          description: 'Your identity has been verified.',
        );
      case 'under_review':
        return _StatusConfig(
          color: ColorConstants.info,
          icon: Icons.hourglass_top,
          label: 'Under Review',
          description: 'Your documents are being reviewed by our team.',
        );
      case 'rejected':
        return _StatusConfig(
          color: ColorConstants.error,
          icon: Icons.cancel_outlined,
          label: 'Rejected',
          description: 'Your KYC was rejected. See reason below.',
        );
      case null:
        return _StatusConfig(
          color: ColorConstants.textSecondaryLight,
          icon: Icons.help_outline,
          label: 'Not Submitted',
          description: 'KYC verification has not been submitted yet.',
        );
      default:
        return _StatusConfig(
          color: ColorConstants.warning,
          icon: Icons.pending_outlined,
          label: 'Pending',
          description: 'Your submission is pending review.',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  final String description;
  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
    required this.description,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: ColorConstants.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    final displayValue = (value == null || value.toString().isEmpty)
        ? '—'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: ColorConstants.textSecondaryLight,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoEntry {
  final String label;
  final dynamic url;
  const _PhotoEntry(this.label, this.url);
}

class _PhotoSectionCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<_PhotoEntry> photos;
  final void Function(String url, String label) onPhotoTap;

  const _PhotoSectionCard({
    required this.isDark,
    required this.title,
    required this.photos,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final validPhotos = photos
        .where((p) => p.url != null && p.url.toString().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: ColorConstants.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  '${validPhotos.length} / ${photos.length}',
                  style: const TextStyle(
                    color: ColorConstants.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: photos.map((entry) {
                final hasUrl =
                    entry.url != null && entry.url.toString().isNotEmpty;
                return _PhotoRow(
                  label: entry.label,
                  url: hasUrl ? entry.url.toString() : null,
                  isDark: isDark,
                  onTap: hasUrl
                      ? () => onPhotoTap(entry.url.toString(), entry.label)
                      : null,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final String label;
  final String? url;
  final bool isDark;
  final VoidCallback? onTap;

  const _PhotoRow({
    required this.label,
    required this.isDark,
    this.url,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Thumbnail
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 48,
                child: url != null
                    ? Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(isDark),
                      )
                    : _placeholder(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url != null ? 'Tap to view' : 'Not uploaded',
                  style: TextStyle(
                    fontSize: 11,
                    color: url != null
                        ? ColorConstants.primary
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (url != null)
            IconButton(
              icon: const Icon(
                Icons.open_in_new,
                size: 18,
                color: ColorConstants.primary,
              ),
              onPressed: onTap,
              tooltip: 'View full image',
            ),
        ],
      ),
    );
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark
          ? ColorConstants.surfaceVariantDark
          : ColorConstants.surfaceVariantLight,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: ColorConstants.textSecondaryLight,
        size: 24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen photo viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullPhotoViewer extends StatelessWidget {
  final String url;
  final String label;

  const _FullPhotoViewer({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 64),
                SizedBox(height: 12),
                Text(
                  'Unable to load image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
