import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const Color _black = Color(0xFF000000);
  static const Color _onyx = Color(0xFF111111);
  static const Color _lime = Color(0xFFAAFF00);
  static const Color _grey = Color(0xFF999999);
  static const Color _white = Color(0xFFFFFFFF);
 
  // Semantic
  static const Color background   = _black;
  static const Color surface      = _onyx;
  static const Color accent       = _lime;
  static const Color textPrimary  = _white;
  static const Color textSecondary = _grey;
 
  // Utility
  static const Color divider = Color(0xFF222222);
  static const Color buttonDisabled = Color(0xFF333333);
}