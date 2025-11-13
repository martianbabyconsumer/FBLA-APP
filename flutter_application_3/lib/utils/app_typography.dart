import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography system
/// - Outfit: For titles, headings, and app branding
/// - Inter: For body text, buttons, and general UI
class AppTypography {
  
  // ============== APP BRANDING ==============
  
  /// App name style (FBLA HIVE) - Outfit Black
  static TextStyle appTitle(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 20,
      fontWeight: FontWeight.w900, // Black
      letterSpacing: 0.6,
      color: color ?? Theme.of(context).appBarTheme.foregroundColor,
    );
  }
  
  // ============== PAGE TITLES ==============
  
  /// Page title (Settings, Home, etc.) - Outfit Bold
  static TextStyle pageTitle(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  // ============== SECTION HEADINGS ==============
  
  /// Section heading - Outfit SemiBold
  static TextStyle sectionHeading(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600, // SemiBold
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  /// Subsection heading - Outfit Medium
  static TextStyle subsectionHeading(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.w500, // Medium
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  // ============== CARD/POST TITLES ==============
  
  /// Post/Card title - Outfit Bold
  static TextStyle cardTitle(BuildContext context, {Color? color}) {
    return GoogleFonts.outfit(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  // ============== BODY TEXT ==============
  
  /// Body text large - Inter Regular
  static TextStyle bodyLarge(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  /// Body text medium - Inter Regular
  static TextStyle bodyMedium(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      height: 1.5,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  /// Body text small - Inter Regular
  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      height: 1.4,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  // ============== BUTTONS ==============
  
  /// Button text - Inter SemiBold
  static TextStyle button(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: color,
    );
  }
  
  /// Button text small - Inter SemiBold
  static TextStyle buttonSmall(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: color,
    );
  }
  
  // ============== LABELS & CAPTIONS ==============
  
  /// Label text - Inter Medium
  static TextStyle label(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
  }
  
  /// Caption text - Inter Regular
  static TextStyle caption(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );
  }
  
  // ============== SPECIAL TEXT ==============
  
  /// Username/Handle - Inter Medium
  static TextStyle username(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
  }
  
  /// Display name - Inter Bold
  static TextStyle displayName(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
  
  /// Tag text - Inter SemiBold
  static TextStyle tag(BuildContext context, {Color? color}) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}

/// Extension to easily apply typography styles
extension TypographyExtension on Text {
  Text withStyle(TextStyle Function(BuildContext) styleBuilder, BuildContext context) {
    return Text(
      data ?? '',
      style: styleBuilder(context).merge(style),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
