import 'package:flutter/material.dart';

/// Interactive container that triggers a center-outward expanding hover animation
/// from the horizontal middle outward to the left and right edges.
class ExpandHoverHighlight extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? hoverColor;
  final bool isSelected;
  final Color? selectedColor;
  final HitTestBehavior behavior;

  const ExpandHoverHighlight({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.hoverColor,
    this.isSelected = false,
    this.selectedColor,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ExpandHoverHighlight> createState() => _ExpandHoverHighlightState();
}

class _ExpandHoverHighlightState extends State<ExpandHoverHighlight> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultHoverColor =
        isDark ? const Color(0xFF1E1E22) : const Color(0xFFF4F4F5);
    final activeHoverColor = widget.hoverColor ?? defaultHoverColor;
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Selected state static pill background
            if (widget.isSelected && widget.selectedColor != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.selectedColor,
                    borderRadius: radius,
                  ),
                ),
              )
            else
              // Middle-outward horizontal expansion hover animation
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _isHovered ? 1.0 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: _isHovered ? Curves.easeOutCubic : Curves.easeInCubic,
                  builder: (context, factor, _) {
                    if (factor <= 0.001) return const SizedBox.shrink();
                    return FractionallySizedBox(
                      widthFactor: factor,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: factor.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: activeHoverColor,
                            borderRadius: radius,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Foreground content with padding ensuring gap on edges
            Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
