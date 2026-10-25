import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../config/theme.dart';

class ResponsiveMobileFrame extends StatefulWidget {
  final Widget child;

  const ResponsiveMobileFrame({super.key, required this.child});

  @override
  State<ResponsiveMobileFrame> createState() => _ResponsiveMobileFrameState();
}

class _ResponsiveMobileFrameState extends State<ResponsiveMobileFrame> {
  bool _enableMockDeviceFrame = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet = constraints.maxWidth > 650;

        if (!isDesktopOrTablet || !_enableMockDeviceFrame) {
          return widget.child;
        }

        // On desktop/tablet, center the mobile screen within a sleek phone canvas
        return Scaffold(
          backgroundColor: const Color(0xFF121215),
          body: Stack(
            children: [
              // Ambient background glow
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.2,
                      colors: [
                        Color(0xFF1E1E24), // Neutral dark grey glow
                        Color(0xFF121215), // Deep dark grey background
                      ],
                    ),
                  ),
                ),
              ),

              // Desktop Header Bar with Controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181C).withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF27272A),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // App logo & title
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Fin Sail',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Web Mobile View',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Supabase connection status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SupabaseConfig.isDemoMode
                              ? Colors.amber.withOpacity(0.15)
                              : const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: SupabaseConfig.isDemoMode
                                ? Colors.amber.withOpacity(0.4)
                                : const Color(0xFF10B981).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SupabaseConfig.isDemoMode
                                    ? Colors.amber
                                    : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              SupabaseConfig.isDemoMode ? 'Demo Mode (Mock)' : 'Supabase Active',
                              style: TextStyle(
                                color: SupabaseConfig.isDemoMode ? Colors.amber[300] : const Color(0xFF6EE7B7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            _enableMockDeviceFrame = !_enableMockDeviceFrame;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            _enableMockDeviceFrame ? Icons.fullscreen : Icons.stay_current_portrait,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Centered Mobile Mockup Container
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64, bottom: 24),
                  child: Container(
                    width: 420,
                    constraints: const BoxConstraints(maxHeight: 880),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(
                        color: const Color(0xFF27272A),
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 8,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.15),
                          blurRadius: 60,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Stack(
                        children: [
                          // App Content
                          Positioned.fill(child: widget.child),

                          // Dynamic Island / Speaker Pill Mockup (Non-interactive)
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 110,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1E293B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF0F172A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
