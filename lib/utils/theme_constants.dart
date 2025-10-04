import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Colors - Neutral Patriotic Theme
  static const Color primary = Color(0xFFFF9933); // Deep saffron
  static const Color secondary = Color(0xFF138808); // Forest green
  static const Color accent = Color(0xFFFFFFFF); // White

  // Background Colors
  static const Color background = Color(0xFFf9fafb);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1f2937);
  static const Color textSecondary = Color(0xFF6b7280);
  static const Color textMuted = Color(0xFF9ca3af);

  // Border Colors
  static const Color borderLight = Color(0xFFe5e7eb);
  static const Color borderMedium = Color(0xFFd1d5db);

  // Status Colors
  static const Color success = Color(0xFF10b981);
  static const Color error = Color(0xFFef4444);
  static const Color warning = Color(0xFFf59e0b);
  static const Color info = Color(0xFF3b82f6);

  // SnackBar Colors
  static const Color snackBarSuccess = Color(0xFF4CAF50); // Green
  static const Color snackBarError = Color(0xFFF44336); // Red
  static const Color snackBarWarning = Color(0xFFFFC107); // Yellow
  static const Color snackBarTextLight = Colors.white;
  static const Color snackBarTextDark = Colors.black;

  // Social Colors
  static const Color facebook = Color(0xFF1877f2);
  static const Color twitter = Color(0xFF1da1f2);
  static const Color instagram = Color(0xFFe4405f);
  static const Color youtube = Color(0xFFff0000);
  static const Color linkedin = Color(0xFF0077b5);

  // Party Colors (can be dynamic based on candidate)
  static const Map<String, List<Color>> partyGradients = {
    'Indian National Congress': [Color(0xFF3b82f6), Color(0xFF1d4ed8)],
    'Bharatiya Janata Party': [Color(0xFFf97316), Color(0xFFea580c)],
    'Nationalist Congress Party': [Color(0xFF3b82f6), Color(0xFF1e40af)],
    'Shiv Sena': [Color(0xFFdc2626), Color(0xFFb91c1c)],
    'Maharashtra Navnirman Sena': [Color(0xFF16a34a), Color(0xFF15803d)],
    'Communist Party of India': [Color(0xFFdc2626), Color(0xFFb91c1c)],
    'Bahujan Samaj Party': [Color(0xFF1e40af), Color(0xFF1e3a8a)],
    'Samajwadi Party': [Color(0xFFdc2626), Color(0xFFb91c1c)],
    'All India Majlis-e-Ittehad-ul-Muslimeen': [
      Color(0xFF16a34a),
      Color(0xFF15803d),
    ],
  };
}

class AppTypography {
   // Headings
   static TextStyle heading1 = GoogleFonts.notoSans(
     fontSize: 32,
     fontWeight: FontWeight.bold,
     color: AppColors.textPrimary,
     height: 1.2,
   );

   static TextStyle heading2 = GoogleFonts.notoSans(
     fontSize: 24,
     fontWeight: FontWeight.bold,
     color: AppColors.textPrimary,
     height: 1.3,
   );

   static TextStyle heading3 = GoogleFonts.notoSans(
     fontSize: 20,
     fontWeight: FontWeight.bold,
     color: AppColors.textPrimary,
     height: 1.4,
   );

   static TextStyle heading4 = GoogleFonts.notoSans(
     fontSize: 18,
     fontWeight: FontWeight.w600,
     color: AppColors.textPrimary,
     height: 1.4,
   );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
    height: 1.4,
  );

  // Labels and Captions
  static TextStyle labelLarge = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle labelMedium = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle caption = GoogleFonts.notoSans(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
}

class AppShadows {
  static const BoxShadow light = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  static const BoxShadow heavy = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 12,
    offset: Offset(0, 6),
  );
}

