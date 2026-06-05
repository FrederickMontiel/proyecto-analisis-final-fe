import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const mobileMaxWidth = 800.0;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= mobileMaxWidth;
  }

  static double getGridColumns(BuildContext context) {
    return isDesktop(context) ? 4 : 2;
  }

  static double getPadding(BuildContext context) {
    return isDesktop(context) ? 24 : 16;
  }

  static double getSpacing(BuildContext context) {
    return isDesktop(context) ? 16 : 12;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.1;
    return baseSize;
  }

  static int getActionsPerRow(BuildContext context) {
    return isDesktop(context) ? 3 : 1;
  }
}
