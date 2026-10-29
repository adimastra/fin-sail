import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'dashboard_screen.dart';
import 'keypad_expense_screen.dart';
import 'receipt_scanner_modal.dart';
import 'settings_screen.dart';
import 'transactions_list_screen.dart';
import '../widgets/expand_hover_highlight.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Start on Home Page (Middle tab index 1)
  int _currentIndex = 1;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 3 Tabs requested:
    // 0: Analytics (Left)
    // 1: Home Page Overview (Middle, Default)
    // 2: Settings (Right)
    final screens = [
      TransactionsListScreen(key: ValueKey('TransactionsListScreen-$_currentIndex')),
      DashboardScreen(onNavigateTab: _onTabTapped),
      const SettingsScreen(),
    ];

    // Show floating buttons on all pages EXCLUDE settings (index 2)
    final showFloatingButtons = _currentIndex != 2;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C0E) : Colors.white,
      body: Stack(
        children: [
          // Main tab pages
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),

          // Fixed Floating Action Buttons (Bottom Right, Pinned Position)
          if (showFloatingButtons)
            Positioned(
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 1. Scan Receipt Circular Button (Scales up on hover - 3/4 size of Add Expense button: 48px vs 64px)
                  _HoverScaleButton(
                    size: 48,
                    backgroundColor: isDark ? Colors.white : AppTheme.pureBlack,
                    tooltip: 'Scan Receipt',
                    onTap: () => ReceiptScannerModal.show(context),
                    child: Icon(
                      Icons.document_scanner,
                      size: 22,
                      color: isDark ? AppTheme.pureBlack : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Add Manual Expense Circular Button (Bigger FAB: 64px)
                  _HoverScaleButton(
                    size: 64,
                    backgroundColor: isDark ? const Color(0xFF27272A) : AppTheme.pureBlack,
                    tooltip: 'Manual Expense',
                    onTap: () => KeypadExpenseScreen.show(context),
                    child: const Icon(
                      Icons.add,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C0C0E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E1E22) : AppTheme.grayBorder,
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Analytics (Left)
                _buildNavItem(
                  index: 0,
                  icon: Icons.pie_chart_outline_rounded,
                  tooltip: 'Analytics',
                ),

                // 2. Home Page Overview (Middle)
                _buildNavItem(
                  index: 1,
                  icon: Icons.home_outlined,
                  tooltip: 'Home',
                ),

                // 3. Settings (Right)
                _buildNavItem(
                  index: 2,
                  icon: Icons.settings_outlined,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String tooltip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;

    return Tooltip(
      message: tooltip,
      child: ExpandHoverHighlight(
        onTap: () => _onTabTapped(index),
        isSelected: isSelected,
        selectedColor: isDark ? Colors.white : AppTheme.pureBlack,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Icon(
          icon,
          size: 22,
          color: isSelected
              ? (isDark ? AppTheme.pureBlack : Colors.white)
              : AppTheme.grayTextMuted,
        ),
      ),
    );
  }
}

class _HoverScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final double size;
  final Color backgroundColor;

  const _HoverScaleButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    required this.size,
    required this.backgroundColor,
  });

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered ? 1.16 : 1.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.backgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.2),
                    blurRadius: _isHovered ? 16 : 10,
                    offset: Offset(0, _isHovered ? 5 : 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
