import 'package:flutter/material.dart';

/// Utility class for location translations (districts and body types)
/// Contains predefined data with English and Marathi names
class LocationTranslations {
  // District translations for Maharashtra
  static const Map<String, Map<String, String>> districtTranslations = {
    'ahmednagar': {
      'en': 'Ahmednagar',
      'mr': 'अहमदनगर',
    },
    'akola': {
      'en': 'Akola',
      'mr': 'अकोला',
    },
    'amravati': {
      'en': 'Amravati',
      'mr': 'अमरावती',
    },
    'aurangabad': {
      'en': 'Aurangabad',
      'mr': 'औरंगाबाद',
    },
    'beed': {
      'en': 'Beed',
      'mr': 'बीड',
    },
    'bhandara': {
      'en': 'Bhandara',
      'mr': 'भंडारा',
    },
    'buldhana': {
      'en': 'Buldhana',
      'mr': 'बुलढाणा',
    },
    'chandrapur': {
      'en': 'Chandrapur',
      'mr': 'चंद्रपूर',
    },
    'dhule': {
      'en': 'Dhule',
      'mr': 'धुळे',
    },
    'gadchiroli': {
      'en': 'Gadchiroli',
      'mr': 'गडचिरोली',
    },
    'gondia': {
      'en': 'Gondia',
      'mr': 'गोंदिया',
    },
    'hingoli': {
      'en': 'Hingoli',
      'mr': 'हिंगोली',
    },
    'jalgaon': {
      'en': 'Jalgaon',
      'mr': 'जळगाव',
    },
    'jalna': {
      'en': 'Jalna',
      'mr': 'जालना',
    },
    'kolhapur': {
      'en': 'Kolhapur',
      'mr': 'कोल्हापूर',
    },
    'latur': {
      'en': 'Latur',
      'mr': 'लातूर',
    },
    'mumbai_city': {
      'en': 'Mumbai City',
      'mr': 'मुंबई शहर',
    },
    'mumbai_suburban': {
      'en': 'Mumbai Suburban',
      'mr': 'मुंबई उपनगर',
    },
    'nagpur': {
      'en': 'Nagpur',
      'mr': 'नागपूर',
    },
    'nanded': {
      'en': 'Nanded',
      'mr': 'नांदेड',
    },
    'nandurbar': {
      'en': 'Nandurbar',
      'mr': 'नंदूरबार',
    },
    'nashik': {
      'en': 'Nashik',
      'mr': 'नाशिक',
    },
    'osmanabad': {
      'en': 'Osmanabad',
      'mr': 'उस्मानाबाद',
    },
    'palghar': {
      'en': 'Palghar',
      'mr': 'पालघर',
    },
    'parbhani': {
      'en': 'Parbhani',
      'mr': 'परभणी',
    },
    'pune': {
      'en': 'Pune',
      'mr': 'पुणे',
    },
    'raigad': {
      'en': 'Raigad',
      'mr': 'रायगड',
    },
    'ratnagiri': {
      'en': 'Ratnagiri',
      'mr': 'रत्नागिरी',
    },
    'sangli': {
      'en': 'Sangli',
      'mr': 'सांगली',
    },
    'satara': {
      'en': 'Satara',
      'mr': 'सातारा',
    },
    'sindhudurg': {
      'en': 'Sindhudurg',
      'mr': 'सिंधुदुर्ग',
    },
    'solapur': {
      'en': 'Solapur',
      'mr': 'सोलापूर',
    },
    'thane': {
      'en': 'Thane',
      'mr': 'ठाणे',
    },
    'wardha': {
      'en': 'Wardha',
      'mr': 'वर्धा',
    },
    'washim': {
      'en': 'Washim',
      'mr': 'वाशीम',
    },
    'yavatmal': {
      'en': 'Yavatmal',
      'mr': 'यवतमाळ',
    },
  };

  // Body type translations
  static const Map<String, Map<String, String>> bodyTypeTranslations = {
    'municipal_corporation': {
      'en': 'Municipal Corporation',
      'mr': 'महानगरपालिका',
    },
    'municipal_council': {
      'en': 'Municipal Council',
      'mr': 'नगरपरिषद',
    },
    'nagar_panchayat': {
      'en': 'Nagar Panchayat',
      'mr': 'नगरपंचायत',
    },
    'zilla_parishad': {
      'en': 'Zilla Parishad',
      'mr': 'जिल्हा परिषद',
    },
    'panchayat_samiti': {
      'en': 'Panchayat Samiti',
      'mr': 'पंचायत समिती',
    },
    'cantonment_board': {
      'en': 'Cantonment Board',
      'mr': 'कॅन्टोन्मेंट बोर्ड',
    },
    'town_area_committee': {
      'en': 'Town Area Committee',
      'mr': 'टाउन एरिया कमिटी',
    },
    'notified_area_committee': {
      'en': 'Notified Area Committee',
      'mr': 'नोटिफाइड एरिया कमिटी',
    },
    'industrial_township': {
      'en': 'Industrial Township',
      'mr': 'इंडस्ट्रियल टाउनशिप',
    },
  };

  /// Get district display name based on locale
  static String getDistrictDisplayName(String districtId, Locale locale) {
    final translations = districtTranslations[districtId.toLowerCase()];
    if (translations == null) {
      return districtId; // Fallback to ID if not found
    }

    final languageCode = locale.languageCode;
    return translations[languageCode] ?? translations['en'] ?? districtId;
  }

  /// Get body type display name based on locale
  static String getBodyTypeDisplayName(String bodyType, Locale locale) {
    final translations = bodyTypeTranslations[bodyType.toLowerCase()];
    if (translations == null) {
      return bodyType; // Fallback to type if not found
    }

    final languageCode = locale.languageCode;
    return translations[languageCode] ?? translations['en'] ?? bodyType;
  }

  /// Get all districts for a state (currently only Maharashtra)
  static List<Map<String, String>> getDistrictsForState(String stateId) {
    if (stateId.toLowerCase() == 'maharashtra' || stateId.toLowerCase() == 'mh') {
      return districtTranslations.entries.map((entry) {
        return {
          'id': entry.key,
          'name': entry.value['en'] ?? entry.key,
          'marathiName': entry.value['mr'] ?? entry.key,
        };
      }).toList();
    }
    return [];
  }
}