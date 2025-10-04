import 'package:flutter/material.dart';

/// Constants for manifesto editing components
class ManifestoConstants {
  // Colors
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);

  // File type colors
  static const Color pdfColor = Color(0xFFDC2626);
  static const Color imageColor = Color(0xFF059669);
  static const Color videoColor = Color(0xFF7C3AED);

  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 12.0;
  static const double largeSpacing = 16.0;
  static const double extraLargeSpacing = 24.0;

  // Border radius
  static const double smallBorderRadius = 6.0;
  static const double mediumBorderRadius = 8.0;
  static const double largeBorderRadius = 12.0;

  // Font sizes
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double extraLargeFontSize = 18.0;
  static const double titleFontSize = 20.0;

  // Font weights
  static const FontWeight lightFontWeight = FontWeight.w300;
  static const FontWeight regularFontWeight = FontWeight.w400;
  static const FontWeight mediumFontWeight = FontWeight.w500;
  static const FontWeight semiBoldFontWeight = FontWeight.w600;
  static const FontWeight boldFontWeight = FontWeight.w700;

  // File size limits (in MB)
  static const double maxPdfSize = 10.0;
  static const double maxImageSize = 5.0;
  static const double maxVideoSize = 50.0;

  // File type extensions
  static const List<String> pdfExtensions = ['pdf'];
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  ];

  // Strings
  static const String manifestoTitle = 'Manifesto';
  static const String manifestoSubtitle =
      'Share your vision and promises with voters';
  static const String uploadPdfTitle = 'Upload PDF Document';
  static const String uploadImageTitle = 'Upload Image';
  static const String uploadVideoTitle = 'Upload Video';
  static const String pdfFileLimit = 'Max 10MB • PDF format only';
  static const String imageFileLimit = 'Max 5MB • JPG, PNG, GIF, WebP';
  static const String videoFileLimit = 'Max 50MB • MP4, MOV, AVI, MKV, WebM';
  static const String premiumVideo = 'Premium Video Upload';
  static const String premiumFeatureRequired = 'Premium subscription required';
  static const String choosePdf = 'Choose PDF';
  static const String chooseImage = 'Choose Image';
  static const String chooseVideo = 'Choose Video';
  static const String uploadingText = 'Uploading...';
  static const String saveText = 'Save Changes';
  static const String cancelText = 'Cancel';
  static const String deleteText = 'Delete';
  static const String editText = 'Edit';
  static const String viewText = 'View';
  static const String loadingText = 'Loading...';
  static const String errorText = 'Error';
  static const String successText = 'Success';
  static const String warningText = 'Warning';
  static const String infoText = 'Information';

  // Error messages
  static const String fileTooLargeError = 'File size exceeds the maximum limit';
  static const String invalidFileTypeError = 'Invalid file type selected';
  static const String uploadFailedError = 'Upload failed. Please try again';
  static const String networkError =
      'Network error. Please check your connection';
  static const String permissionDeniedError =
      'Permission denied. Please grant access';
  static const String fileNotFoundError = 'File not found';
  static const String unknownError = 'An unknown error occurred';

  // Success messages
  static const String uploadSuccess = 'File uploaded successfully';
  static const String saveSuccess = 'Changes saved successfully';
  static const String deleteSuccess = 'File deleted successfully';

  // Confirmation messages
  static const String deleteConfirmation =
      'Are you sure you want to delete this file?';
  static const String cancelConfirmation =
      'Are you sure you want to cancel? All changes will be lost.';
  static const String saveConfirmation = 'Save changes?';

  // Demo data
  static const String demoPdfName = 'sample_manifesto.pdf';
  static const String demoImageName = 'sample_manifesto_image.jpg';
  static const String demoVideoName = 'sample_manifesto_video.mp4';
  static const String demoPdfUrl = 'https://example.com/sample_manifesto.pdf';
  static const String demoImageUrl =
      'https://example.com/sample_manifesto_image.jpg';
  static const String demoVideoUrl =
      'https://example.com/sample_manifesto_video.mp4';

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Padding values
  static const EdgeInsets smallPadding = EdgeInsets.all(smallSpacing);
  static const EdgeInsets mediumPadding = EdgeInsets.all(mediumSpacing);
  static const EdgeInsets largePadding = EdgeInsets.all(largeSpacing);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: mediumSpacing,
  );
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(
    vertical: mediumSpacing,
  );

  // Box shadows
  static const List<BoxShadow> lightShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> heavyShadow = [
    BoxShadow(color: Color(0x2F000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  // Border styles
  static const BorderSide thinBorder = BorderSide(
    width: 1,
    color: Color(0xFFE5E7EB),
  );
  static const BorderSide mediumBorder = BorderSide(
    width: 2,
    color: Color(0xFFD1D5DB),
  );
  static const BorderSide thickBorder = BorderSide(
    width: 3,
    color: Color(0xFF9CA3AF),
  );

  // Text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: titleFontSize,
    fontWeight: boldFontWeight,
    color: Colors.black87,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: mediumFontSize,
    fontWeight: regularFontWeight,
    color: Colors.grey,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: mediumFontSize,
    fontWeight: regularFontWeight,
    color: Colors.black87,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: smallFontSize,
    fontWeight: regularFontWeight,
    color: Colors.grey,
  );

  static const TextStyle buttonStyle = TextStyle(
    fontSize: mediumFontSize,
    fontWeight: mediumFontWeight,
    color: Colors.white,
  );

  static const TextStyle errorStyle = TextStyle(
    fontSize: smallFontSize,
    fontWeight: mediumFontWeight,
    color: errorColor,
  );

  static const TextStyle successStyle = TextStyle(
    fontSize: smallFontSize,
    fontWeight: mediumFontWeight,
    color: successColor,
  );

  static const TextStyle warningStyle = TextStyle(
    fontSize: smallFontSize,
    fontWeight: mediumFontWeight,
    color: warningColor,
  );
}

/// Extension methods for easier access to constants
extension ManifestoConstantsExtension on BuildContext {
  ManifestoConstants get constants => ManifestoConstants();
}

