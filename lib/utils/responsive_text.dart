import 'package:flutter/material.dart';

/// Responsive text utility for consistent font scaling across the app
/// Based on screen width with base reference of 375px (iPhone SE)
class ResponsiveText {
  ResponsiveText(this.context);

  final BuildContext context;

  double get _scale {
    final screenWidth = MediaQuery.of(context).size.width;
    const baseWidth = 375.0;
    return screenWidth / baseWidth;
  }

  /// Clamped scale between 0.8 and 1.2 to prevent extreme scaling
  double get clampedScale => _scale.clamp(0.8, 1.2);

  /// Responsive font size
  double fontSize(double baseSize) {
    return baseSize * clampedScale;
  }

  /// Responsive spacing
  double spacing(double baseSpacing) {
    return baseSpacing * clampedScale;
  }

  /// Responsive icon size
  double iconSize(double baseSize) {
    return baseSize * clampedScale;
  }

  // Predefined responsive font sizes
  double get fontSize8 => fontSize(8);
  double get fontSize10 => fontSize(10);
  double get fontSize11 => fontSize(11);
  double get fontSize12 => fontSize(12);
  double get fontSize13 => fontSize(13);
  double get fontSize14 => fontSize(14);
  double get fontSize15 => fontSize(15);
  double get fontSize16 => fontSize(16);
  double get fontSize18 => fontSize(18);
  double get fontSize19 => fontSize(19);
  double get fontSize20 => fontSize(20);
  double get fontSize24 => fontSize(24);
  double get fontSize28 => fontSize(28);
  double get fontSize32 => fontSize(32);
  double get fontSize36 => fontSize(36);
  double get fontSize48 => fontSize(48);

  // Predefined responsive spacing
  double get space4 => spacing(4);
  double get space8 => spacing(8);
  double get space12 => spacing(12);
  double get space16 => spacing(16);
  double get space20 => spacing(20);
  double get space24 => spacing(24);
  double get space32 => spacing(32);
  double get space40 => spacing(40);

  // Text styles with responsive fonts
  TextStyle get headline1 => TextStyle(
        fontSize: fontSize(32),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get headline2 => TextStyle(
        fontSize: fontSize(28),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get headline3 => TextStyle(
        fontSize: fontSize(24),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get headline4 => TextStyle(
        fontSize: fontSize(20),
        fontWeight: FontWeight.bold,
        height: 1.2,
      );

  TextStyle get headline5 => TextStyle(
        fontSize: fontSize(18),
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  TextStyle get bodyLarge => TextStyle(
        fontSize: fontSize(16),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get bodyMedium => TextStyle(
        fontSize: fontSize(14),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get bodySmall => TextStyle(
        fontSize: fontSize(12),
        fontWeight: FontWeight.normal,
        height: 1.5,
      );

  TextStyle get caption => TextStyle(
        fontSize: fontSize(11),
        fontWeight: FontWeight.normal,
        height: 1.4,
      );

  TextStyle get button => TextStyle(
        fontSize: fontSize(16),
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  TextStyle get label => TextStyle(
        fontSize: fontSize(14),
        fontWeight: FontWeight.w500,
        height: 1.4,
      );
}

/// Extension method for easy access to ResponsiveText
extension ResponsiveTextExtension on BuildContext {
  ResponsiveText get responsive => ResponsiveText(this);
}
