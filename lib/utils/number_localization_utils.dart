import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for localizing numbers across different locales and numeral systems
class NumberLocalizationUtils {
  // Cache formatters for performance
  static final Map<String, NumberFormat> _formatters = {};

  /// Get a cached NumberFormat for the given locale
  static NumberFormat _getFormatter(String locale) {
    if (!_formatters.containsKey(locale)) {
      _formatters[locale] = NumberFormat('##', locale);
    }
    return _formatters[locale]!;
  }

  /// Convert Western numerals to Devanagari numerals (used in Marathi, Hindi, etc.)
  static String _toDevanagariNumerals(String number) {
    const western = '0123456789';
    const devanagari = '०१२३४५६७८९';

    String result = number;
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], devanagari[i]);
    }
    return result;
  }

  /// Convert Western numerals to Arabic numerals (used in Arabic, Persian, Urdu, etc.)
  static String _toArabicNumerals(String number) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    String result = number;
    for (int i = 0; i < western.length; i++) {
      result = result.replaceAll(western[i], arabic[i]);
    }
    return result;
  }

  /// Convert number to localized string with proper formatting and numeral system
  static String toLocalizedString(int number, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    // First format the number according to locale rules
    final formatted = _getFormatter(locale).format(number);

    // Then convert to appropriate numeral system if needed
    switch (locale) {
      case 'mr': // Marathi
      case 'hi': // Hindi
      case 'ne': // Nepali
        return _toDevanagariNumerals(formatted);
      case 'ar': // Arabic
      case 'fa': // Persian
      case 'ur': // Urdu
        return _toArabicNumerals(formatted);
      default:
        return formatted;
    }
  }

  /// Convert number to localized string with explicit locale
  static String toLocalizedStringWithLocale(int number, String locale) {
    final formatted = _getFormatter(locale).format(number);

    switch (locale) {
      case 'mr':
      case 'hi':
      case 'ne':
        return _toDevanagariNumerals(formatted);
      case 'ar':
      case 'fa':
      case 'ur':
        return _toArabicNumerals(formatted);
      default:
        return formatted;
    }
  }

  /// Format decimal numbers with locale-specific formatting
  static String formatDecimal(double number, BuildContext context, {int decimalPlaces = 2}) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = NumberFormat('0.${'0' * decimalPlaces}', locale);
    final formatted = formatter.format(number);

    switch (locale) {
      case 'mr':
      case 'hi':
      case 'ne':
        return _toDevanagariNumerals(formatted);
      case 'ar':
      case 'fa':
      case 'ur':
        return _toArabicNumerals(formatted);
      default:
        return formatted;
    }
  }

  /// Format currency with locale-specific formatting
  static String formatCurrency(double amount, BuildContext context, {String? currencyCode}) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: currencyCode ?? '₹', // Default to INR
      decimalDigits: 2,
    );
    final formatted = formatter.format(amount);

    switch (locale) {
      case 'mr':
      case 'hi':
      case 'ne':
        return _toDevanagariNumerals(formatted);
      case 'ar':
      case 'fa':
      case 'ur':
        return _toArabicNumerals(formatted);
      default:
        return formatted;
    }
  }

  /// Format percentage with locale-specific formatting
  static String formatPercentage(double percentage, BuildContext context, {int decimalPlaces = 1}) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = NumberFormat.percentPattern(locale);
    final formatted = formatter.format(percentage / 100);

    switch (locale) {
      case 'mr':
      case 'hi':
      case 'ne':
        return _toDevanagariNumerals(formatted);
      case 'ar':
      case 'fa':
      case 'ur':
        return _toArabicNumerals(formatted);
      default:
        return formatted;
    }
  }
}

/// Extension methods for easy usage
extension NumberLocalizationExtensions on int {
  /// Convert integer to localized string
  String toLocalizedString(BuildContext context) {
    return NumberLocalizationUtils.toLocalizedString(this, context);
  }

  /// Convert integer to localized string with explicit locale
  String toLocalizedStringWithLocale(String locale) {
    return NumberLocalizationUtils.toLocalizedStringWithLocale(this, locale);
  }
}

extension DoubleLocalizationExtensions on double {
  /// Convert double to localized decimal string
  String toLocalizedDecimal(BuildContext context, {int decimalPlaces = 2}) {
    return NumberLocalizationUtils.formatDecimal(this, context, decimalPlaces: decimalPlaces);
  }

  /// Convert double to localized currency string
  String toLocalizedCurrency(BuildContext context, {String? currencyCode}) {
    return NumberLocalizationUtils.formatCurrency(this, context, currencyCode: currencyCode);
  }

  /// Convert double to localized percentage string
  String toLocalizedPercentage(BuildContext context, {int decimalPlaces = 1}) {
    return NumberLocalizationUtils.formatPercentage(this, context, decimalPlaces: decimalPlaces);
  }
}