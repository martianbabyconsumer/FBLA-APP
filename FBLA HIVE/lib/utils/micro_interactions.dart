import 'package:flutter/material.dart';

/// Wrapper widget that adds micro-interaction effects (ripple, scale) to any widget
class MicroInteraction extends StatefulWidget {
  const MicroInteraction({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnTap = true,
    this.rippleEffect = true,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool scaleOnTap;
  final bool rippleEffect;
  final double scaleFactor;
  final Duration duration;

  @override
  State<MicroInteraction> createState() => _MicroInteractionState();
}

class _MicroInteractionState extends State<MicroInteraction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.scaleOnTap) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.scaleOnTap) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.scaleOnTap) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.scaleOnTap) {
      content = ScaleTransition(
        scale: _scaleAnimation,
        child: content,
      );
    }

    if (widget.rippleEffect && (widget.onTap != null || widget.onLongPress != null)) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          borderRadius: BorderRadius.circular(12),
          splashFactory: InkRipple.splashFactory,
          child: content,
        ),
      );
    } else if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: content,
      );
    }

    return content;
  }
}

/// Extension on BuildContext to add theme-compatible gradients
extension ThemeGradients on BuildContext {
  /// Primary gradient (theme-compatible)
  LinearGradient get primaryGradient {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return LinearGradient(
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withOpacity(isDark ? 0.7 : 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Secondary gradient (theme-compatible)
  LinearGradient get secondaryGradient {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return LinearGradient(
      colors: [
        theme.colorScheme.secondary,
        theme.colorScheme.secondary.withOpacity(isDark ? 0.7 : 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Surface gradient (subtle, theme-compatible)
  LinearGradient get surfaceGradient {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return LinearGradient(
      colors: [
        theme.colorScheme.surface,
        theme.colorScheme.surfaceContainerHighest.withOpacity(isDark ? 0.5 : 0.3),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Card gradient (subtle elevation effect)
  LinearGradient get cardGradient {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return LinearGradient(
      colors: [
        theme.cardColor,
        isDark 
            ? theme.cardColor.withOpacity(0.95)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Accent gradient (for highlights and accents)
  LinearGradient accentGradient(Color accentColor) {
    final theme = Theme.of(this);
    final isDark = theme.brightness == Brightness.dark;
    
    return LinearGradient(
      colors: [
        accentColor.withOpacity(isDark ? 0.3 : 0.2),
        accentColor.withOpacity(isDark ? 0.15 : 0.1),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// Improved spacing constants (follows 8px grid system)
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  /// Vertical spacing widgets
  static const Widget verticalXS = SizedBox(height: xs);
  static const Widget verticalSM = SizedBox(height: sm);
  static const Widget verticalMD = SizedBox(height: md);
  static const Widget verticalLG = SizedBox(height: lg);
  static const Widget verticalXL = SizedBox(height: xl);
  static const Widget verticalXXL = SizedBox(height: xxl);
  
  /// Horizontal spacing widgets
  static const Widget horizontalXS = SizedBox(width: xs);
  static const Widget horizontalSM = SizedBox(width: sm);
  static const Widget horizontalMD = SizedBox(width: md);
  static const Widget horizontalLG = SizedBox(width: lg);
  static const Widget horizontalXL = SizedBox(width: xl);
  static const Widget horizontalXXL = SizedBox(width: xxl);
}

/// Theme-aware color accents
class AppAccents {
  /// Success color (theme-aware)
  static Color success(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.green[400]! : Colors.green[600]!;
  }

  /// Error color (theme-aware)
  static Color error(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  /// Warning color (theme-aware)
  static Color warning(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.orange[400]! : Colors.orange[700]!;
  }

  /// Info color (theme-aware)
  static Color info(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.blue[400]! : Colors.blue[600]!;
  }
}
