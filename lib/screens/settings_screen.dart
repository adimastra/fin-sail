import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../config/theme.dart';
import '../providers/expense_provider.dart';
import 'manage_categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = 'IDR (Rp)';
  bool _hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.pureBlack,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Google SSO Profile / Fin Sail Branding Card
            Consumer<ExpenseProvider>(
              builder: (context, expProvider, _) {
                final user = expProvider.currentUser;
                final name = user?.displayName ?? 'Fin Sail User';
                final email = user?.email ?? 'user@gmail.com';
                final avatar = user?.avatarUrl;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF27272A) : AppTheme.grayBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF27272A) : Colors.white,
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                            width: 2,
                          ),
                          image: avatar != null
                              ? DecorationImage(
                                  image: NetworkImage(avatar),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: avatar == null
                            ? Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'F',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppTheme.pureBlack,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      color: isDark ? Colors.white : AppTheme.pureBlack,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SSO',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppTheme.grayTextMuted,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Preferences
            const Text(
              'preferences',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grayTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Theme Mode Switch Menu (Dark, Light, Use System)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: isDark ? Colors.white70 : AppTheme.pureBlack,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.pureBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _buildThemeOption(
                          label: 'Dark Mode',
                          icon: Icons.dark_mode_outlined,
                          isSelected: provider.themeMode == ThemeMode.dark,
                          onTap: () => provider.setThemeMode(ThemeMode.dark),
                        ),
                        _buildThemeOption(
                          label: 'Light Mode',
                          icon: Icons.light_mode_outlined,
                          isSelected: provider.themeMode == ThemeMode.light,
                          onTap: () => provider.setThemeMode(ThemeMode.light),
                        ),
                        _buildThemeOption(
                          label: 'Use System',
                          icon: Icons.settings_brightness_outlined,
                          isSelected: provider.themeMode == ThemeMode.system,
                          onTap: () => provider.setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              icon: Icons.attach_money,
              title: 'Currency',
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCurrency,
                  items: const [
                    DropdownMenuItem(
                      value: 'USD (\$)',
                      child: Text('USD (\$)'),
                    ),
                    DropdownMenuItem(value: 'EUR (€)', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'GBP (£)', child: Text('GBP (£)')),
                    DropdownMenuItem(
                      value: 'IDR (Rp)',
                      child: Text('IDR (Rp)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCurrency = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              icon: Icons.vibration,
              title: 'Haptic Feedback',
              trailing: Switch.adaptive(
                value: _hapticFeedback,
                activeThumbColor: isDark ? Colors.white : AppTheme.pureBlack,
                onChanged: (val) => setState(() => _hapticFeedback = val),
              ),
            ),
            const SizedBox(height: 28),

            // Categories
            const Text(
              'categories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grayTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.category_outlined,
              title: 'Manage Categories',
              subtitle:
                  '${provider.categories.where((c) => !c.isDefault).length} custom • ${provider.categories.where((c) => c.isDefault).length} default',
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white54 : AppTheme.grayTextMuted,
                size: 20,
              ),
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Backend & Supabase
            const Text(
              'cloud & storage',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grayTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.cloud_outlined,
              title: 'Supabase Database',
              subtitle: SupabaseConfig.isDemoMode
                  ? 'Demo Mode (Local mock)'
                  : 'Connected',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  SupabaseConfig.isDemoMode ? 'Mock' : 'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : AppTheme.pureBlack,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            _buildSettingTile(
              icon: Icons.document_scanner_outlined,
              title: 'AI Receipt Parser',
              subtitle: 'Gemini 2.5 Flash Vision',
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 10),
              _buildSettingTile(
                icon: Icons.hourglass_top_rounded,
                title: 'Test Skeleton Loader',
                subtitle: 'Simulate 2.5s network fetch delay',
                trailing: TextButton(
                  onPressed: () {
                    provider.refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Simulating 2.5s fetch delay. Check Overview or Analytics!',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Reload',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.pureBlack,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // Account & SSO
            const Text(
              'account & sso',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.grayTextMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.logout_rounded,
              title: 'Sign Out',
              subtitle: 'Disconnect current session',
              textColor: const Color(0xFFEF4444),
              iconColor: const Color(0xFFEF4444),
              onTap: () => _confirmSignOut(context, provider),
            ),
            const SizedBox(height: 32),

            // Version info & Developer attribution (Requested)
            Center(
              child: Column(
                children: [
                  const Text(
                    'version 1.0.0 • Fin Sail',
                    style: TextStyle(
                      color: AppTheme.grayTextMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Developed by Adimastra',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppTheme.pureBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, ExpenseProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF18181B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.pureBlack,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out from Fin Sail?',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.grayTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white70 : AppTheme.pureBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await provider.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white : AppTheme.pureBlack)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (isDark ? AppTheme.pureBlack : Colors.white)
                    : AppTheme.grayTextMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppTheme.pureBlack : Colors.white)
                      : (isDark ? Colors.white70 : AppTheme.pureBlack),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? (isDark ? Colors.white70 : AppTheme.pureBlack),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? (isDark ? Colors.white : AppTheme.pureBlack),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.grayTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppTheme.grayKeypad,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: rowContent,
              )
            : rowContent,
      ),
    );
  }
}
