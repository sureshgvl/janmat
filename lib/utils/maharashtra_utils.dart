import 'package:flutter/material.dart';
import 'app_logger.dart';

/// Comprehensive utility for Maharashtra administrative divisions
/// Provides centralized access to districts, wards, and local body types with multilingual support
class MaharashtraUtils {
  /// All districts in Maharashtra with multilingual support
  static const List<Map<String, String>> districts = [
    {
      "key": "mumbai_city",
      "nameEn": "Mumbai City",
      "nameMr": "मुंबई शहर",
      "region": "Konkan"
    },
    {
      "key": "mumbai_suburban",
      "nameEn": "Mumbai Suburban",
      "nameMr": "मुंबई उपनगर",
      "region": "Konkan"
    },
    {
      "key": "thane",
      "nameEn": "Thane",
      "nameMr": "ठाणे",
      "region": "Konkan"
    },
    {
      "key": "palghar",
      "nameEn": "Palghar",
      "nameMr": "पालघर",
      "region": "Konkan"
    },
    {
      "key": "raigad",
      "nameEn": "Raigad",
      "nameMr": "रायगड",
      "region": "Konkan"
    },
    {
      "key": "ratnagiri",
      "nameEn": "Ratnagiri",
      "nameMr": "रत्नागिरी",
      "region": "Konkan"
    },
    {
      "key": "sindhudurg",
      "nameEn": "Sindhudurg",
      "nameMr": "सिंधुदुर्ग",
      "region": "Konkan"
    },
    {
      "key": "nashik",
      "nameEn": "Nashik",
      "nameMr": "नाशिक",
      "region": "Nashik"
    },
    {
      "key": "dhule",
      "nameEn": "Dhule",
      "nameMr": "धुळे",
      "region": "Nashik"
    },
    {
      "key": "jalgaon",
      "nameEn": "Jalgaon",
      "nameMr": "जळगाव",
      "region": "Nashik"
    },
    {
      "key": "ahilyanagar",
      "nameEn": "Ahilyanagar",
      "nameMr": "अहिल्यानगर",
      "region": "Nashik"
    },
    {
      "key": "nandurbar",
      "nameEn": "Nandurbar",
      "nameMr": "नंदुरबार",
      "region": "Nashik"
    },
    {
      "key": "pune",
      "nameEn": "Pune",
      "nameMr": "पुणे",
      "region": "Pune"
    },
    {
      "key": "satara",
      "nameEn": "Satara",
      "nameMr": "सातारा",
      "region": "Pune"
    },
    {
      "key": "sangli",
      "nameEn": "Sangli",
      "nameMr": "सांगली",
      "region": "Pune"
    },
    {
      "key": "solapur",
      "nameEn": "Solapur",
      "nameMr": "सोलापूर",
      "region": "Pune"
    },
    {
      "key": "kolhapur",
      "nameEn": "Kolhapur",
      "nameMr": "कोल्हापूर",
      "region": "Pune"
    },
    {
      "key": "chhatrapati_sambhajinagar",
      "nameEn": "Chhatrapati Sambhajinagar",
      "nameMr": "छत्रपती संभाजीनगर",
      "region": "Aurangabad"
    },
    {
      "key": "jalna",
      "nameEn": "Jalna",
      "nameMr": "जालना",
      "region": "Aurangabad"
    },
    {
      "key": "parbhani",
      "nameEn": "Parbhani",
      "nameMr": "परभणी",
      "region": "Aurangabad"
    },
    {
      "key": "hingoli",
      "nameEn": "Hingoli",
      "nameMr": "हिंगोली",
      "region": "Aurangabad"
    },
    {
      "key": "nanded",
      "nameEn": "Nanded",
      "nameMr": "नांदेड",
      "region": "Aurangabad"
    },
    {
      "key": "latur",
      "nameEn": "Latur",
      "nameMr": "लातूर",
      "region": "Aurangabad"
    },
    {
      "key": "dharashiv",
      "nameEn": "Dharashiv",
      "nameMr": "धाराशिव",
      "region": "Aurangabad"
    },
    {
      "key": "beed",
      "nameEn": "Beed",
      "nameMr": "बीड",
      "region": "Aurangabad"
    },
    {
      "key": "akola",
      "nameEn": "Akola",
      "nameMr": "अकोला",
      "region": "Amravati"
    },
    {
      "key": "amravati",
      "nameEn": "Amravati",
      "nameMr": "अमरावती",
      "region": "Amravati"
    },
    {
      "key": "buldhana",
      "nameEn": "Buldhana",
      "nameMr": "बुलढाणा",
      "region": "Amravati"
    },
    {
      "key": "washim",
      "nameEn": "Washim",
      "nameMr": "वाशिम",
      "region": "Amravati"
    },
    {
      "key": "yavatmal",
      "nameEn": "Yavatmal",
      "nameMr": "यवतमाळ",
      "region": "Amravati"
    },
    {
      "key": "nagpur",
      "nameEn": "Nagpur",
      "nameMr": "नागपूर",
      "region": "Nagpur"
    },
    {
      "key": "wardha",
      "nameEn": "Wardha",
      "nameMr": "वर्धा",
      "region": "Nagpur"
    },
    {
      "key": "bhandara",
      "nameEn": "Bhandara",
      "nameMr": "भंडारा",
      "region": "Nagpur"
    },
    {
      "key": "gondia",
      "nameEn": "Gondia",
      "nameMr": "गोंदिया",
      "region": "Nagpur"
    },
    {
      "key": "chandrapur",
      "nameEn": "Chandrapur",
      "nameMr": "चंद्रपूर",
      "region": "Nagpur"
    },
    {
      "key": "gadchiroli",
      "nameEn": "Gadchiroli",
      "nameMr": "गडचिरोली",
      "region": "Nagpur"
    }
  ];

  /// Wards from 1 to 300 with multilingual support
  static const List<Map<String, String>> wards = [
    {"key": "ward_1", "nameEn": "Ward 1", "nameMr": "वार्ड १"},
    {"key": "ward_2", "nameEn": "Ward 2", "nameMr": "वार्ड २"}
  ];

  /// Local body types in Maharashtra with multilingual support
  static const List<Map<String, String>> localBodyTypes = [
    {
      "key": "municipal_corporation",
      "nameEn": "Municipal Corporation",
      "nameMr": "महानगरपालिका",
      "category": "Urban"
    },
    {
      "key": "municipal_council",
      "nameEn": "Municipal Council",
      "nameMr": "नगरपरिषद",
      "category": "Urban"
    },
    {
      "key": "nagar_panchayat",
      "nameEn": "Nagar Panchayat",
      "nameMr": "नगर पंचायत",
      "category": "Urban"
    },
    {
      "key": "panchayat_samiti",
      "nameEn": "Panchayat Samiti",
      "nameMr": "पंचायत समिती",
      "category": "Rural"
    },
    {
      "key": "zilla_parishad",
      "nameEn": "Zilla Parishad",
      "nameMr": "जिल्हा परिषद",
      "category": "Rural"
    },
    {
      "key": "gram_panchayat",
      "nameEn": "Gram Panchayat",
      "nameMr": "ग्राम पंचायत",
      "category": "Rural"
    },
    {
      "key": "cantonment_board",
      "nameEn": "Cantonment Board",
      "nameMr": "छावणी परिषद",
      "category": "Special"
    },
    {
      "key": "town_area_committee",
      "nameEn": "Town Area Committee",
      "nameMr": "नगर क्षेत्र समिती",
      "category": "Urban"
    },
    {
      "key": "notified_area_committee",
      "nameEn": "Notified Area Committee",
      "nameMr": "अधिसूचित क्षेत्र समिती",
      "category": "Urban"
    },
    {
      "key": "industrial_township",
      "nameEn": "Industrial Township",
      "nameMr": "औद्योगिक नगरपालिका",
      "category": "Special"
    }
  ];

  
  // ===== DISTRICT METHODS =====

  /// Get district by key
  static Map<String, String>? getDistrictByKey(String key) {
    try {
      return districts.firstWhere(
        (district) => district['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      AppLogger.common('Error finding district by key $key: $e');
      return null;
    }
  }

  /// Get district display name (automatically detects locale)
  static String getDistrictDisplayName(String key) {
    final district = getDistrictByKey(key);
    if (district == null) return key;

    // Default to English name, fallback to key
    return district['nameEn'] ?? key;
  }

  /// Get district display name with explicit locale preference
  static String getDistrictDisplayNameWithLocale(String key, String locale) {
    final district = getDistrictByKey(key);
    if (district == null) return key;

    if (locale == 'mr' && district['nameMr'] != null) {
      return district['nameMr']!;
    }

    return district['nameEn'] ?? key;
  }

  /// Get all districts for a specific region
  static List<Map<String, String>> getDistrictsByRegion(String region) {
    return districts.where((district) => district['region'] == region).toList();
  }

  /// Get all available regions
  static List<String> getAllRegions() {
    return districts.map((district) => district['region']!).toSet().toList();
  }

  // ===== WARD METHODS =====

  /// Get ward by key
  static Map<String, String>? getWardByKey(String key) {
    try {
      return wards.firstWhere(
        (ward) => ward['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      AppLogger.common('Error finding ward by key $key: $e');
      return null;
    }
  }

  /// Get ward display name (automatically detects locale)
  static String getWardDisplayName(String key) {
    final ward = getWardByKey(key);
    if (ward == null) return key;

    // Default to English name, fallback to key
    return ward['nameEn'] ?? key;
  }

  /// Get ward display name with explicit locale preference
  static String getWardDisplayNameWithLocale(String key, String locale) {
    final ward = getWardByKey(key);
    if (ward == null) return key;

    if (locale == 'mr' && ward['nameMr'] != null) {
      return ward['nameMr']!;
    }

    return ward['nameEn'] ?? key;
  }

  /// Get ward number from key (e.g., "ward_25" -> 25)
  static int? getWardNumber(String key) {
    try {
      final parts = key.split('_');
      if (parts.length == 2 && parts[0] == 'ward') {
        return int.parse(parts[1]);
      }
      return null;
    } catch (e) {
      AppLogger.common('Error parsing ward number from key $key: $e');
      return null;
    }
  }

  /// Get ward key from number (e.g., 25 -> "ward_25")
  static String getWardKeyFromNumber(int number) {
    return 'ward_$number';
  }

  // ===== LOCAL BODY TYPE METHODS =====

  /// Get local body type by key
  static Map<String, String>? getLocalBodyTypeByKey(String key) {
    try {
      return localBodyTypes.firstWhere(
        (type) => type['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      AppLogger.common('Error finding local body type by key $key: $e');
      return null;
    }
  }

  /// Get local body type display name (automatically detects locale)
  static String getLocalBodyTypeDisplayName(String key) {
    final type = getLocalBodyTypeByKey(key);
    if (type == null) return key;

    // Default to English name, fallback to key
    return type['nameEn'] ?? key;
  }

  /// Get local body type display name with explicit locale preference
  static String getLocalBodyTypeDisplayNameWithLocale(String key, String locale) {
    final type = getLocalBodyTypeByKey(key);
    if (type == null) return key;

    if (locale == 'mr' && type['nameMr'] != null) {
      return type['nameMr']!;
    }

    return type['nameEn'] ?? key;
  }

  /// Get all local body types for a specific category
  static List<Map<String, String>> getLocalBodyTypesByCategory(String category) {
    return localBodyTypes.where((type) => type['category'] == category).toList();
  }

  /// Get all available categories
  static List<String> getAllCategories() {
    return localBodyTypes.map((type) => type['category']!).toSet().toList();
  }

  // ===== UTILITY METHODS =====

  /// Get current locale for translation
  static String getCurrentLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode; // Returns 'en' or 'mr'
  }

  /// Get all district keys for reference
  static List<String> getAllDistrictKeys() {
    return districts.map((district) => district['key']!).toList();
  }

  /// Get all ward keys for reference
  static List<String> getAllWardKeys() {
    return wards.map((ward) => ward['key']!).toList();
  }

  /// Get all local body type keys for reference
  static List<String> getAllLocalBodyTypeKeys() {
    return localBodyTypes.map((type) => type['key']!).toList();
  }

  /// Get district display name based on locale (equivalent to LocationTranslations)
  static String getDistrictDisplayNameV2(String districtId, Locale locale) {
    final district = getDistrictByKey(districtId);
    if (district == null) return districtId;

    final languageCode = locale.languageCode;
    if (languageCode == 'mr' && district['nameMr'] != null) {
      return district['nameMr']!;
    }

    return district['nameEn'] ?? districtId;
  }

  /// Get body type display name based on locale (equivalent to LocationTranslations)
  static String getBodyTypeDisplayNameV2(String bodyType, Locale locale) {
    final type = getLocalBodyTypeByKey(bodyType);
    if (type == null) return bodyType;

    final languageCode = locale.languageCode;
    if (languageCode == 'mr' && type['nameMr'] != null) {
      return type['nameMr']!;
    }

    return type['nameEn'] ?? bodyType;
  }


  /// Search districts by name (English or Marathi)
  static List<Map<String, String>> searchDistricts(String query) {
    final lowerQuery = query.toLowerCase();
    return districts.where((district) {
      return district['nameEn']!.toLowerCase().contains(lowerQuery) ||
             district['nameMr']!.toLowerCase().contains(lowerQuery) ||
             district['key']!.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search wards by name or number
  static List<Map<String, String>> searchWards(String query) {
    final lowerQuery = query.toLowerCase();
    return wards.where((ward) {
      return ward['nameEn']!.toLowerCase().contains(lowerQuery) ||
             ward['nameMr']!.toLowerCase().contains(lowerQuery) ||
             ward['key']!.toLowerCase().contains(lowerQuery) ||
             getWardNumber(ward['key']!)?.toString().contains(lowerQuery) == true;
    }).toList();
  }

  /// Search local body types by name
  static List<Map<String, String>> searchLocalBodyTypes(String query) {
    final lowerQuery = query.toLowerCase();
    return localBodyTypes.where((type) {
      return type['nameEn']!.toLowerCase().contains(lowerQuery) ||
             type['nameMr']!.toLowerCase().contains(lowerQuery) ||
             type['key']!.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
