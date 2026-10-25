import 'package:flutter/material.dart';
import '../config/theme.dart';

class SkeletonPulse extends StatefulWidget {
  final Widget child;

  const SkeletonPulse({super.key, required this.child});

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : AppTheme.grayKeypad,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class HomeOverviewSkeleton extends StatelessWidget {
  const HomeOverviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Big Headline Amount Skeleton
            const SkeletonBox(width: 220, height: 44, borderRadius: 16),
            const SizedBox(height: 24),

            // 5-Month Wave Chart Skeleton Card
            const SkeletonBox(width: double.infinity, height: 160, borderRadius: 24),
            const SizedBox(height: 32),

            // Section Header Skeleton
            Row(
              children: const [
                SkeletonBox(width: 60, height: 14, borderRadius: 6),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 1, borderRadius: 1)),
                SizedBox(width: 12),
                SkeletonBox(width: 80, height: 14, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 16),

            // Transaction Tiles Skeletons
            for (int i = 0; i < 4; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const SkeletonBox(width: 44, height: 44, borderRadius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 120, height: 14, borderRadius: 6),
                          SizedBox(height: 6),
                          SkeletonBox(width: 70, height: 11, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SkeletonBox(width: 90, height: 16, borderRadius: 6),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AnalyticsSkeleton extends StatelessWidget {
  final int selectedTab;

  const AnalyticsSkeleton({super.key, this.selectedTab = 1});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: selectedTab == 0
            ? _buildTransactionsTabSkeleton(context)
            : _buildChartTabSkeleton(context),
      ),
    );
  }

  // Skeleton for Tab 0: All Expense Transaction (NO chart!)
  Widget _buildTransactionsTabSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Filter Date button skeleton on left, Tab Menu Toggle skeleton on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 95, height: 38, borderRadius: 16),
            SkeletonBox(width: 72, height: 38, borderRadius: 24),
          ],
        ),
        const SizedBox(height: 14),

        // Search Bar Skeleton (full width)
        const SkeletonBox(width: double.infinity, height: 46, borderRadius: 20),
        const SizedBox(height: 12),

        // Category & Receipt Filter Chips Skeleton
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            children: const [
              SkeletonBox(width: 48, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonBox(width: 82, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonBox(width: 74, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonBox(width: 88, height: 32, borderRadius: 16),
              SizedBox(width: 8),
              SkeletonBox(width: 92, height: 32, borderRadius: 16),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Summary count and total skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 110, height: 16, borderRadius: 6),
            SkeletonBox(width: 100, height: 16, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 16),

        // Date Section Header Skeleton (e.g. today)
        Row(
          children: const [
            SkeletonBox(width: 50, height: 13, borderRadius: 4),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 1, borderRadius: 1)),
            SizedBox(width: 12),
            SkeletonBox(width: 75, height: 13, borderRadius: 4),
          ],
        ),
        const SizedBox(height: 12),

        // Transaction items skeleton
        for (int i = 0; i < 4; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const SkeletonBox(width: 44, height: 44, borderRadius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 130, height: 14, borderRadius: 6),
                      SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                const SkeletonBox(width: 85, height: 16, borderRadius: 6),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Skeleton for Tab 1: Chart by categories
  Widget _buildChartTabSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Row: Month/Year filter chip on left, Tab Menu Toggle on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 105, height: 38, borderRadius: 16),
            SkeletonBox(width: 72, height: 38, borderRadius: 24),
          ],
        ),
        const SizedBox(height: 16),

        // Donut Chart Skeleton with Center Text
        Center(
          child: SizedBox(
            height: 220,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF27272A)
                          : AppTheme.grayKeypad,
                      width: 24,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SkeletonBox(width: 90, height: 13, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 130, height: 24, borderRadius: 6),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Header: "All Expenses" Skeleton
        const SkeletonBox(width: 110, height: 18, borderRadius: 6),
        const SizedBox(height: 14),

        // Category Cards Skeleton
        for (int i = 0; i < 4; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF27272A)
                    : AppTheme.grayBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SkeletonBox(width: 44, height: 44, borderRadius: 14),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SkeletonBox(width: 110, height: 15, borderRadius: 6),
                          SizedBox(height: 6),
                          SkeletonBox(width: 70, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        SkeletonBox(width: 85, height: 15, borderRadius: 6),
                        SizedBox(height: 6),
                        SkeletonBox(width: 75, height: 12, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const SkeletonBox(width: double.infinity, height: 5, borderRadius: 4),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class DetailExpenseSkeleton extends StatelessWidget {
  const DetailExpenseSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Emoji + Merchant title + Date + Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  SkeletonBox(width: 24, height: 24, borderRadius: 12),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 140, height: 16, borderRadius: 6),
                      SizedBox(height: 6),
                      SkeletonBox(width: 90, height: 11, borderRadius: 4),
                    ],
                  ),
                ],
              ),
              const SkeletonBox(width: 95, height: 18, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 1, borderRadius: 1),
          const SizedBox(height: 16),

          // Category Pill Skeleton
          const SkeletonBox(width: 85, height: 26, borderRadius: 13),
          const SizedBox(height: 20),

          // Extracted Items Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonBox(width: 130, height: 14, borderRadius: 6),
              SkeletonBox(width: 50, height: 12, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 12),

          // Extracted Line Items Skeletons
          for (int i = 0; i < 3; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  SkeletonBox(width: 6, height: 6, borderRadius: 3),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonBox(height: 13, borderRadius: 4)),
                  SizedBox(width: 16),
                  SkeletonBox(width: 70, height: 13, borderRadius: 4),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Button Skeleton
          const SkeletonBox(width: double.infinity, height: 48, borderRadius: 16),
        ],
      ),
    );
  }
}

class DetailChartSkeleton extends StatelessWidget {
  const DetailChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Month & Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 130, height: 18, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 12, borderRadius: 4),
                ],
              ),
              SkeletonBox(width: 110, height: 18, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 1, borderRadius: 1),
          const SizedBox(height: 16),

          // List of Transaction Tiles Skeletons
          for (int i = 0; i < 4; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: const [
                  SkeletonBox(width: 44, height: 44, borderRadius: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 120, height: 14, borderRadius: 6),
                        SizedBox(height: 6),
                        SkeletonBox(width: 75, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 80, height: 15, borderRadius: 6),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
