import 'package:flutter/material.dart';

// New Color Scheme
class AppColors {
  static const Color primaryTeal = Color(0xFF015055); // Dark teal
  static const Color accentYellowGreen = Color(0xFFE2F299); // Light yellow-green
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  
  // Additional colors for compatibility
  static const Color secondaryColor = Colors.white;
  static const Color textColor = Color(0xFF015055); // Dark teal for text
  static const Color lightTextColor = Color(0xFF6B7280); // Grey for light text
  static const Color transparent = Colors.transparent;
  
  // Accent colors
  static const Color grey = Color(0xFF9CA3AF);
  static const Color purple = Color(0xFF9333EA);
  static const Color orange = Color(0xFFF97316);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
}

// Legacy constants for backward compatibility
const primaryColor = AppColors.primaryTeal;
const secondaryColor = AppColors.secondaryColor;
const bgColor = AppColors.backgroundColor;
const textColor = AppColors.textColor;
const lightTextColor = AppColors.lightTextColor;
const transparent = AppColors.transparent;
const grey = AppColors.grey;
const purple = AppColors.purple;
const orange = AppColors.orange;
const green = AppColors.green;
const red = AppColors.red;

// Default App Padding
const appPadding = 16.0;
