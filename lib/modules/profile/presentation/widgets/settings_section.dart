import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/controllers/theme_controller.dart';

class SettingsSection extends StatelessWidget {
  final ThemeController themeController;
  final VoidCallback onSignOut;

  const SettingsSection({
    super.key,
    required this.themeController,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Temporarily hidden theme toggle
          // ListenableBuilder(
          //   listenable: themeController,
          //   builder: (context, _) {
          //     return _buildSettingTile(
          //       icon: themeController.isDarkMode
          //           ? Icons.light_mode_rounded
          //           : Icons.dark_mode_rounded,
          //       title: 'Theme',
          //       subtitle: themeController.isDarkMode ? 'Dark Mode' : 'Light Mode',
          //       trailing: Switch(
          //         value: themeController.isDarkMode,
          //         onChanged: (value) => themeController.toggleTheme(),
          //         activeTrackColor: ColorConstants.primary,
          //       ),
          //       theme: theme,
          //       isDark: isDark,
          //     );
          //   },
          // ),
          // Divider(
          //   height: 1,
          //   indent: 72,
          //   color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
          // ),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Log out from your account',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: ColorConstants.error,
            ),
            onTap: onSignOut,
            theme: theme,
            isDark: isDark,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required ThemeData theme,
    required bool isDark,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDestructive
              ? ColorConstants.error.withValues(alpha: 0.1)
              : ColorConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? ColorConstants.error : ColorConstants.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? ColorConstants.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
