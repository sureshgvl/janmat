/// Utility class for election types and districts in Maharashtra
/// Provides centralized access to election types and districts with multilingual support
class ElectionTypeUtils {
  /// All election types with multilingual support
  static const List<Map<String, String>> electionTypes = [
    {
      "key": "lok_sabha",
      "nameMr": "लोकसभा",
      "nameEn": "Lok Sabha"
    },
    {
      "key": "vidhan_sabha",
      "nameMr": "विधानसभा",
      "nameEn": "Vidhan Sabha"
    },
    {
      "key": "zilla_parishad",
      "nameMr": "जिल्हा परिषद",
      "nameEn": "Zilla Parishad"
    },
    {
      "key": "panchayat_samiti",
      "nameMr": "पंचायत समिती",
      "nameEn": "Panchayat Samiti"
    },
    {
      "key": "gram_panchayat",
      "nameMr": "ग्राम पंचायत",
      "nameEn": "Gram Panchayat"
    },
    {
      "key": "municipal_corporation",
      "nameMr": "महानगरपालिका",
      "nameEn": "Municipal Corporation"
    },
    {
      "key": "municipal_council",
      "nameMr": "नगरपरिषद",
      "nameEn": "Municipal Council"
    },
    {
      "key": "nagar_panchayat",
      "nameMr": "नगर पंचायत",
      "nameEn": "Nagar Panchayat"
    }    
  ];

  /// All districts in Maharashtra with multilingual support
  static const List<Map<String, String>> districts = [
    {
      "districtId": "mumbai_city",
      "nameEn": "Mumbai City",
      "nameMr": "मुंबई शहर"
    },
    {
      "districtId": "mumbai_suburban",
      "nameEn": "Mumbai Suburban",
      "nameMr": "मुंबई उपनगर"
    },
    {
      "districtId": "thane",
      "nameEn": "Thane",
      "nameMr": "ठाणे"
    },
    {
      "districtId": "palghar",
      "nameEn": "Palghar",
      "nameMr": "पालघर"
    },
    {
      "districtId": "raigad",
      "nameEn": "Raigad",
      "nameMr": "रायगड"
    },
    {
      "districtId": "ratnagiri",
      "nameEn": "Ratnagiri",
      "nameMr": "रत्नागिरी"
    },
    {
      "districtId": "sindhudurg",
      "nameEn": "Sindhudurg",
      "nameMr": "सिंधुदुर्ग"
    },
    {
      "districtId": "nashik",
      "nameEn": "Nashik",
      "nameMr": "नाशिक"
    },
    {
      "districtId": "dhule",
      "nameEn": "Dhule",
      "nameMr": "धुळे"
    },
    {
      "districtId": "jalgaon",
      "nameEn": "Jalgaon",
      "nameMr": "जळगाव"
    },
    {
      "districtId": "ahmednagar",
      "nameEn": "Ahmednagar",
      "nameMr": "अहमदनगर"
    },
    {
      "districtId": "nandurbar",
      "nameEn": "Nandurbar",
      "nameMr": "नंदुरबार"
    },
    {
      "districtId": "pune",
      "nameEn": "Pune",
      "nameMr": "पुणे"
    },
    {
      "districtId": "satara",
      "nameEn": "Satara",
      "nameMr": "सातारा"
    },
    {
      "districtId": "sangli",
      "nameEn": "Sangli",
      "nameMr": "सांगली"
    },
    {
      "districtId": "solapur",
      "nameEn": "Solapur",
      "nameMr": "सोलापूर"
    },
    {
      "districtId": "kolhapur",
      "nameEn": "Kolhapur",
      "nameMr": "कोल्हापूर"
    },
    {
      "districtId": "aurangabad",
      "nameEn": "Aurangabad",
      "nameMr": "औरंगाबाद"
    },
    {
      "districtId": "jalna",
      "nameEn": "Jalna",
      "nameMr": "जालना"
    },
    {
      "districtId": "parbhani",
      "nameEn": "Parbhani",
      "nameMr": "परभणी"
    },
    {
      "districtId": "hingoli",
      "nameEn": "Hingoli",
      "nameMr": "हिंगोली"
    },
    {
      "districtId": "nanded",
      "nameEn": "Nanded",
      "nameMr": "नांदेड"
    },
    {
      "districtId": "latur",
      "nameEn": "Latur",
      "nameMr": "लातूर"
    },
    {
      "districtId": "osmanabad",
      "nameEn": "Osmanabad",
      "nameMr": "उस्मानाबाद"
    },
    {
      "districtId": "beed",
      "nameEn": "Beed",
      "nameMr": "बीड"
    },
    {
      "districtId": "akola",
      "nameEn": "Akola",
      "nameMr": "अकोला"
    },
    {
      "districtId": "amravati",
      "nameEn": "Amravati",
      "nameMr": "अमरावती"
    },
    {
      "districtId": "buldhana",
      "nameEn": "Buldhana",
      "nameMr": "बुलढाणा"
    },
    {
      "districtId": "washim",
      "nameEn": "Washim",
      "nameMr": "वाशिम"
    },
    {
      "districtId": "yavatmal",
      "nameEn": "Yavatmal",
      "nameMr": "यवतमाळ"
    },
    {
      "districtId": "nagpur",
      "nameEn": "Nagpur",
      "nameMr": "नागपूर"
    },
    {
      "districtId": "wardha",
      "nameEn": "Wardha",
      "nameMr": "वर्धा"
    },
    {
      "districtId": "bhandara",
      "nameEn": "Bhandara",
      "nameMr": "भंडारा"
    },
    {
      "districtId": "gondia",
      "nameEn": "Gondia",
      "nameMr": "गोंदिया"
    },
    {
      "districtId": "chandrapur",
      "nameEn": "Chandrapur",
      "nameMr": "चंद्रपूर"
    },
    {
      "districtId": "gadchiroli",
      "nameEn": "Gadchiroli",
      "nameMr": "गडचिरोली"
    }
  ];


  /// Get election type by key
  static Map<String, String>? getElectionTypeByKey(String key) {
    try {
      return electionTypes.firstWhere(
        (type) => type['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      return null;
    }
  }

  /// Get district by districtId
  static Map<String, String>? getDistrictById(String districtId) {
    try {
      return districts.firstWhere(
        (district) => district['districtId'] == districtId,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      return null;
    }
  }

  /// Get election type display name with locale
  static String getElectionTypeDisplayName(String key, String locale) {
    final type = getElectionTypeByKey(key);
    if (type == null) return key;

    if (locale == 'mr' && type['nameMr'] != null) {
      return type['nameMr']!;
    }
    return type['nameEn'] ?? key;
  }

  /// Get district display name with locale
  static String getDistrictDisplayName(String districtId, String locale) {
    final district = getDistrictById(districtId);
    if (district == null) return districtId;

    if (locale == 'mr' && district['nameMr'] != null) {
      return district['nameMr']!;
    }
    return district['nameEn'] ?? districtId;
  }

  /// Get all election type keys
  static List<String> getAllElectionTypeKeys() {
    return electionTypes.map((type) => type['key']!).toList();
  }

  /// Get all district IDs
  static List<String> getAllDistrictIds() {
    return districts.map((district) => district['districtId']!).toList();
  }

  /// Search election types by name
  static List<Map<String, String>> searchElectionTypes(String query) {
    final lowerQuery = query.toLowerCase();
    return electionTypes.where((type) {
      return type['nameEn']!.toLowerCase().contains(lowerQuery) ||
             type['nameMr']!.toLowerCase().contains(lowerQuery) ||
             type['key']!.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Search districts by name
  static List<Map<String, String>> searchDistricts(String query) {
    final lowerQuery = query.toLowerCase();
    return districts.where((district) {
      return district['nameEn']!.toLowerCase().contains(lowerQuery) ||
             district['nameMr']!.toLowerCase().contains(lowerQuery) ||
             district['districtId']!.contains(lowerQuery);
    }).toList();
  }
}