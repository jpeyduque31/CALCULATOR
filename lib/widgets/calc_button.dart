import 'package:flutter/material.dart';

class CalcButton extends StatefulWidget {
  const CalcButton({
    super.key,
    required this.label,
    this.onPressed,
    this.accent = false,
    this.secondary = false,
    this.primary = false,
    this.isWide = false,
    this.textColor,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool accent;
  final bool secondary;
  final bool primary;
  final bool isWide;
  final Color? textColor;
  final Color? color;

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Color buttonColor = widget.color ??
        (widget.primary
            ? colors.primary
            : widget.accent
                ? colors.secondary
                : widget.secondary
                    ? colors.tertiaryContainer
                    : colors.surfaceContainerHighest);

    final Color foregroundColor = widget.primary || widget.accent
        ? colors.onPrimary
        : widget.secondary
            ? colors.onTertiaryContainer
            : colors.onSurface;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: widget.isWide ? double.infinity : null,
          height: 68,
          constraints: const BoxConstraints(minHeight: 68),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(
              widget.label,
              style: theme.textTheme.headlineSmall?.copyWith(
                    color: widget.textColor ?? foregroundColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ) ??
                  TextStyle(
                    color: widget.textColor ?? foregroundColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
