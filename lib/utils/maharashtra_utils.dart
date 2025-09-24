import 'package:flutter/material.dart';

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
      "key": "ahmednagar",
      "nameEn": "Ahmednagar",
      "nameMr": "अहमदनगर",
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
      "key": "aurangabad",
      "nameEn": "Aurangabad",
      "nameMr": "औरंगाबाद",
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
      "key": "osmanabad",
      "nameEn": "Osmanabad",
      "nameMr": "उस्मानाबाद",
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
    {"key": "ward_2", "nameEn": "Ward 2", "nameMr": "वार्ड २"},
    {"key": "ward_3", "nameEn": "Ward 3", "nameMr": "वार्ड ३"},
    {"key": "ward_4", "nameEn": "Ward 4", "nameMr": "वार्ड ४"},
    {"key": "ward_5", "nameEn": "Ward 5", "nameMr": "वार्ड ५"},
    {"key": "ward_6", "nameEn": "Ward 6", "nameMr": "वार्ड ६"},
    {"key": "ward_7", "nameEn": "Ward 7", "nameMr": "वार्ड ७"},
    {"key": "ward_8", "nameEn": "Ward 8", "nameMr": "वार्ड ८"},
    {"key": "ward_9", "nameEn": "Ward 9", "nameMr": "वार्ड ९"},
    {"key": "ward_10", "nameEn": "Ward 10", "nameMr": "वार्ड १०"},
    {"key": "ward_11", "nameEn": "Ward 11", "nameMr": "वार्ड ११"},
    {"key": "ward_12", "nameEn": "Ward 12", "nameMr": "वार्ड १२"},
    {"key": "ward_13", "nameEn": "Ward 13", "nameMr": "वार्ड १३"},
    {"key": "ward_14", "nameEn": "Ward 14", "nameMr": "वार्ड १४"},
    {"key": "ward_15", "nameEn": "Ward 15", "nameMr": "वार्ड १५"},
    {"key": "ward_16", "nameEn": "Ward 16", "nameMr": "वार्ड १६"},
    {"key": "ward_17", "nameEn": "Ward 17", "nameMr": "वार्ड १७"},
    {"key": "ward_18", "nameEn": "Ward 18", "nameMr": "वार्ड १८"},
    {"key": "ward_19", "nameEn": "Ward 19", "nameMr": "वार्ड १९"},
    {"key": "ward_20", "nameEn": "Ward 20", "nameMr": "वार्ड २०"},
    {"key": "ward_21", "nameEn": "Ward 21", "nameMr": "वार्ड २१"},
    {"key": "ward_22", "nameEn": "Ward 22", "nameMr": "वार्ड २२"},
    {"key": "ward_23", "nameEn": "Ward 23", "nameMr": "वार्ड २३"},
    {"key": "ward_24", "nameEn": "Ward 24", "nameMr": "वार्ड २४"},
    {"key": "ward_25", "nameEn": "Ward 25", "nameMr": "वार्ड २५"},
    {"key": "ward_26", "nameEn": "Ward 26", "nameMr": "वार्ड २६"},
    {"key": "ward_27", "nameEn": "Ward 27", "nameMr": "वार्ड २७"},
    {"key": "ward_28", "nameEn": "Ward 28", "nameMr": "वार्ड २८"},
    {"key": "ward_29", "nameEn": "Ward 29", "nameMr": "वार्ड २९"},
    {"key": "ward_30", "nameEn": "Ward 30", "nameMr": "वार्ड ३०"},
    {"key": "ward_31", "nameEn": "Ward 31", "nameMr": "वार्ड ३१"},
    {"key": "ward_32", "nameEn": "Ward 32", "nameMr": "वार्ड ३२"},
    {"key": "ward_33", "nameEn": "Ward 33", "nameMr": "वार्ड ३३"},
    {"key": "ward_34", "nameEn": "Ward 34", "nameMr": "वार्ड ३४"},
    {"key": "ward_35", "nameEn": "Ward 35", "nameMr": "वार्ड ३५"},
    {"key": "ward_36", "nameEn": "Ward 36", "nameMr": "वार्ड ३६"},
    {"key": "ward_37", "nameEn": "Ward 37", "nameMr": "वार्ड ३७"},
    {"key": "ward_38", "nameEn": "Ward 38", "nameMr": "वार्ड ३८"},
    {"key": "ward_39", "nameEn": "Ward 39", "nameMr": "वार्ड ३९"},
    {"key": "ward_40", "nameEn": "Ward 40", "nameMr": "वार्ड ४०"},
    {"key": "ward_41", "nameEn": "Ward 41", "nameMr": "वार्ड ४१"},
    {"key": "ward_42", "nameEn": "Ward 42", "nameMr": "वार्ड ४२"},
    {"key": "ward_43", "nameEn": "Ward 43", "nameMr": "वार्ड ४३"},
    {"key": "ward_44", "nameEn": "Ward 44", "nameMr": "वार्ड ४४"},
    {"key": "ward_45", "nameEn": "Ward 45", "nameMr": "वार्ड ४५"},
    {"key": "ward_46", "nameEn": "Ward 46", "nameMr": "वार्ड ४६"},
    {"key": "ward_47", "nameEn": "Ward 47", "nameMr": "वार्ड ४७"},
    {"key": "ward_48", "nameEn": "Ward 48", "nameMr": "वार्ड ४८"},
    {"key": "ward_49", "nameEn": "Ward 49", "nameMr": "वार्ड ४९"},
    {"key": "ward_50", "nameEn": "Ward 50", "nameMr": "वार्ड ५०"},
    {"key": "ward_51", "nameEn": "Ward 51", "nameMr": "वार्ड ५१"},
    {"key": "ward_52", "nameEn": "Ward 52", "nameMr": "वार्ड ५२"},
    {"key": "ward_53", "nameEn": "Ward 53", "nameMr": "वार्ड ५३"},
    {"key": "ward_54", "nameEn": "Ward 54", "nameMr": "वार्ड ५४"},
    {"key": "ward_55", "nameEn": "Ward 55", "nameMr": "वार्ड ५५"},
    {"key": "ward_56", "nameEn": "Ward 56", "nameMr": "वार्ड ५६"},
    {"key": "ward_57", "nameEn": "Ward 57", "nameMr": "वार्ड ५७"},
    {"key": "ward_58", "nameEn": "Ward 58", "nameMr": "वार्ड ५८"},
    {"key": "ward_59", "nameEn": "Ward 59", "nameMr": "वार्ड ५९"},
    {"key": "ward_60", "nameEn": "Ward 60", "nameMr": "वार्ड ६०"},
    {"key": "ward_61", "nameEn": "Ward 61", "nameMr": "वार्ड ६१"},
    {"key": "ward_62", "nameEn": "Ward 62", "nameMr": "वार्ड ६२"},
    {"key": "ward_63", "nameEn": "Ward 63", "nameMr": "वार्ड ६३"},
    {"key": "ward_64", "nameEn": "Ward 64", "nameMr": "वार्ड ६४"},
    {"key": "ward_65", "nameEn": "Ward 65", "nameMr": "वार्ड ६५"},
    {"key": "ward_66", "nameEn": "Ward 66", "nameMr": "वार्ड ६६"},
    {"key": "ward_67", "nameEn": "Ward 67", "nameMr": "वार्ड ६७"},
    {"key": "ward_68", "nameEn": "Ward 68", "nameMr": "वार्ड ६८"},
    {"key": "ward_69", "nameEn": "Ward 69", "nameMr": "वार्ड ६९"},
    {"key": "ward_70", "nameEn": "Ward 70", "nameMr": "वार्ड ७०"},
    {"key": "ward_71", "nameEn": "Ward 71", "nameMr": "वार्ड ७१"},
    {"key": "ward_72", "nameEn": "Ward 72", "nameMr": "वार्ड ७२"},
    {"key": "ward_73", "nameEn": "Ward 73", "nameMr": "वार्ड ७३"},
    {"key": "ward_74", "nameEn": "Ward 74", "nameMr": "वार्ड ७४"},
    {"key": "ward_75", "nameEn": "Ward 75", "nameMr": "वार्ड ७५"},
    {"key": "ward_76", "nameEn": "Ward 76", "nameMr": "वार्ड ७६"},
    {"key": "ward_77", "nameEn": "Ward 77", "nameMr": "वार्ड ७७"},
    {"key": "ward_78", "nameEn": "Ward 78", "nameMr": "वार्ड ७८"},
    {"key": "ward_79", "nameEn": "Ward 79", "nameMr": "वार्ड ७९"},
    {"key": "ward_80", "nameEn": "Ward 80", "nameMr": "वार्ड ८०"},
    {"key": "ward_81", "nameEn": "Ward 81", "nameMr": "वार्ड ८१"},
    {"key": "ward_82", "nameEn": "Ward 82", "nameMr": "वार्ड ८२"},
    {"key": "ward_83", "nameEn": "Ward 83", "nameMr": "वार्ड ८३"},
    {"key": "ward_84", "nameEn": "Ward 84", "nameMr": "वार्ड ८४"},
    {"key": "ward_85", "nameEn": "Ward 85", "nameMr": "वार्ड ८५"},
    {"key": "ward_86", "nameEn": "Ward 86", "nameMr": "वार्ड ८६"},
    {"key": "ward_87", "nameEn": "Ward 87", "nameMr": "वार्ड ८७"},
    {"key": "ward_88", "nameEn": "Ward 88", "nameMr": "वार्ड ८८"},
    {"key": "ward_89", "nameEn": "Ward 89", "nameMr": "वार्ड ८९"},
    {"key": "ward_90", "nameEn": "Ward 90", "nameMr": "वार्ड ९०"},
    {"key": "ward_91", "nameEn": "Ward 91", "nameMr": "वार्ड ९१"},
    {"key": "ward_92", "nameEn": "Ward 92", "nameMr": "वार्ड ९२"},
    {"key": "ward_93", "nameEn": "Ward 93", "nameMr": "वार्ड ९३"},
    {"key": "ward_94", "nameEn": "Ward 94", "nameMr": "वार्ड ९४"},
    {"key": "ward_95", "nameEn": "Ward 95", "nameMr": "वार्ड ९५"},
    {"key": "ward_96", "nameEn": "Ward 96", "nameMr": "वार्ड ९६"},
    {"key": "ward_97", "nameEn": "Ward 97", "nameMr": "वार्ड ९७"},
    {"key": "ward_98", "nameEn": "Ward 98", "nameMr": "वार्ड ९८"},
    {"key": "ward_99", "nameEn": "Ward 99", "nameMr": "वार्ड ९९"},
    {"key": "ward_100", "nameEn": "Ward 100", "nameMr": "वार्ड १००"},
    {"key": "ward_101", "nameEn": "Ward 101", "nameMr": "वार्ड १०१"},
    {"key": "ward_102", "nameEn": "Ward 102", "nameMr": "वार्ड १०२"},
    {"key": "ward_103", "nameEn": "Ward 103", "nameMr": "वार्ड १०३"},
    {"key": "ward_104", "nameEn": "Ward 104", "nameMr": "वार्ड १०४"},
    {"key": "ward_105", "nameEn": "Ward 105", "nameMr": "वार्ड १०५"},
    {"key": "ward_106", "nameEn": "Ward 106", "nameMr": "वार्ड १०६"},
    {"key": "ward_107", "nameEn": "Ward 107", "nameMr": "वार्ड १०७"},
    {"key": "ward_108", "nameEn": "Ward 108", "nameMr": "वार्ड १०८"},
    {"key": "ward_109", "nameEn": "Ward 109", "nameMr": "वार्ड १०९"},
    {"key": "ward_110", "nameEn": "Ward 110", "nameMr": "वार्ड ११०"},
    {"key": "ward_111", "nameEn": "Ward 111", "nameMr": "वार्ड १११"},
    {"key": "ward_112", "nameEn": "Ward 112", "nameMr": "वार्ड ११२"},
    {"key": "ward_113", "nameEn": "Ward 113", "nameMr": "वार्ड ११३"},
    {"key": "ward_114", "nameEn": "Ward 114", "nameMr": "वार्ड ११४"},
    {"key": "ward_115", "nameEn": "Ward 115", "nameMr": "वार्ड ११५"},
    {"key": "ward_116", "nameEn": "Ward 116", "nameMr": "वार्ड ११६"},
    {"key": "ward_117", "nameEn": "Ward 117", "nameMr": "वार्ड ११७"},
    {"key": "ward_118", "nameEn": "Ward 118", "nameMr": "वार्ड ११८"},
    {"key": "ward_119", "nameEn": "Ward 119", "nameMr": "वार्ड ११९"},
    {"key": "ward_120", "nameEn": "Ward 120", "nameMr": "वार्ड १२०"},
    {"key": "ward_121", "nameEn": "Ward 121", "nameMr": "वार्ड १२१"},
    {"key": "ward_122", "nameEn": "Ward 122", "nameMr": "वार्ड १२२"},
    {"key": "ward_123", "nameEn": "Ward 123", "nameMr": "वार्ड १२३"},
    {"key": "ward_124", "nameEn": "Ward 124", "nameMr": "वार्ड १२४"},
    {"key": "ward_125", "nameEn": "Ward 125", "nameMr": "वार्ड १२५"},
    {"key": "ward_126", "nameEn": "Ward 126", "nameMr": "वार्ड १२६"},
    {"key": "ward_127", "nameEn": "Ward 127", "nameMr": "वार्ड १२७"},
    {"key": "ward_128", "nameEn": "Ward 128", "nameMr": "वार्ड १२८"},
    {"key": "ward_129", "nameEn": "Ward 129", "nameMr": "वार्ड १२९"},
    {"key": "ward_130", "nameEn": "Ward 130", "nameMr": "वार्ड १३०"},
    {"key": "ward_131", "nameEn": "Ward 131", "nameMr": "वार्ड १३१"},
    {"key": "ward_132", "nameEn": "Ward 132", "nameMr": "वार्ड १३२"},
    {"key": "ward_133", "nameEn": "Ward 133", "nameMr": "वार्ड १३३"},
    {"key": "ward_134", "nameEn": "Ward 134", "nameMr": "वार्ड १३४"},
    {"key": "ward_135", "nameEn": "Ward 135", "nameMr": "वार्ड १३५"},
    {"key": "ward_136", "nameEn": "Ward 136", "nameMr": "वार्ड १३६"},
    {"key": "ward_137", "nameEn": "Ward 137", "nameMr": "वार्ड १३७"},
    {"key": "ward_138", "nameEn": "Ward 138", "nameMr": "वार्ड १३८"},
    {"key": "ward_139", "nameEn": "Ward 139", "nameMr": "वार्ड १३९"},
    {"key": "ward_140", "nameEn": "Ward 140", "nameMr": "वार्ड १४०"},
    {"key": "ward_141", "nameEn": "Ward 141", "nameMr": "वार्ड १४१"},
    {"key": "ward_142", "nameEn": "Ward 142", "nameMr": "वार्ड १४२"},
    {"key": "ward_143", "nameEn": "Ward 143", "nameMr": "वार्ड १४३"},
    {"key": "ward_144", "nameEn": "Ward 144", "nameMr": "वार्ड १४४"},
    {"key": "ward_145", "nameEn": "Ward 145", "nameMr": "वार्ड १४५"},
    {"key": "ward_146", "nameEn": "Ward 146", "nameMr": "वार्ड १४६"},
    {"key": "ward_147", "nameEn": "Ward 147", "nameMr": "वार्ड १४७"},
    {"key": "ward_148", "nameEn": "Ward 148", "nameMr": "वार्ड १४८"},
    {"key": "ward_149", "nameEn": "Ward 149", "nameMr": "वार्ड १४९"},
    {"key": "ward_150", "nameEn": "Ward 150", "nameMr": "वार्ड १५०"},
    {"key": "ward_151", "nameEn": "Ward 151", "nameMr": "वार्ड १५१"},
    {"key": "ward_152", "nameEn": "Ward 152", "nameMr": "वार्ड १५२"},
    {"key": "ward_153", "nameEn": "Ward 153", "nameMr": "वार्ड १५३"},
    {"key": "ward_154", "nameEn": "Ward 154", "nameMr": "वार्ड १५४"},
    {"key": "ward_155", "nameEn": "Ward 155", "nameMr": "वार्ड १५५"},
    {"key": "ward_156", "nameEn": "Ward 156", "nameMr": "वार्ड १५६"},
    {"key": "ward_157", "nameEn": "Ward 157", "nameMr": "वार्ड १५७"},
    {"key": "ward_158", "nameEn": "Ward 158", "nameMr": "वार्ड १५८"},
    {"key": "ward_159", "nameEn": "Ward 159", "nameMr": "वार्ड १५९"},
    {"key": "ward_160", "nameEn": "Ward 160", "nameMr": "वार्ड १६०"},
    {"key": "ward_161", "nameEn": "Ward 161", "nameMr": "वार्ड १६१"},
    {"key": "ward_162", "nameEn": "Ward 162", "nameMr": "वार्ड १६२"},
    {"key": "ward_163", "nameEn": "Ward 163", "nameMr": "वार्ड १६३"},
    {"key": "ward_164", "nameEn": "Ward 164", "nameMr": "वार्ड १६४"},
    {"key": "ward_165", "nameEn": "Ward 165", "nameMr": "वार्ड १६५"},
    {"key": "ward_166", "nameEn": "Ward 166", "nameMr": "वार्ड १६६"},
    {"key": "ward_167", "nameEn": "Ward 167", "nameMr": "वार्ड १६७"},
    {"key": "ward_168", "nameEn": "Ward 168", "nameMr": "वार्ड १६८"},
    {"key": "ward_169", "nameEn": "Ward 169", "nameMr": "वार्ड १६९"},
    {"key": "ward_170", "nameEn": "Ward 170", "nameMr": "वार्ड १७०"},
    {"key": "ward_171", "nameEn": "Ward 171", "nameMr": "वार्ड १७१"},
    {"key": "ward_172", "nameEn": "Ward 172", "nameMr": "वार्ड १७२"},
    {"key": "ward_173", "nameEn": "Ward 173", "nameMr": "वार्ड १७३"},
    {"key": "ward_174", "nameEn": "Ward 174", "nameMr": "वार्ड १७४"},
    {"key": "ward_175", "nameEn": "Ward 175", "nameMr": "वार्ड १७५"},
    {"key": "ward_176", "nameEn": "Ward 176", "nameMr": "वार्ड १७६"},
    {"key": "ward_177", "nameEn": "Ward 177", "nameMr": "वार्ड १७७"},
    {"key": "ward_178", "nameEn": "Ward 178", "nameMr": "वार्ड १७८"},
    {"key": "ward_179", "nameEn": "Ward 179", "nameMr": "वार्ड १७९"},
    {"key": "ward_180", "nameEn": "Ward 180", "nameMr": "वार्ड १८०"},
    {"key": "ward_181", "nameEn": "Ward 181", "nameMr": "वार्ड १८१"},
    {"key": "ward_182", "nameEn": "Ward 182", "nameMr": "वार्ड १८२"},
    {"key": "ward_183", "nameEn": "Ward 183", "nameMr": "वार्ड १८३"},
    {"key": "ward_184", "nameEn": "Ward 184", "nameMr": "वार्ड १८४"},
    {"key": "ward_185", "nameEn": "Ward 185", "nameMr": "वार्ड १८५"},
    {"key": "ward_186", "nameEn": "Ward 186", "nameMr": "वार्ड १८६"},
    {"key": "ward_187", "nameEn": "Ward 187", "nameMr": "वार्ड १८७"},
    {"key": "ward_188", "nameEn": "Ward 188", "nameMr": "वार्ड १८८"},
    {"key": "ward_189", "nameEn": "Ward 189", "nameMr": "वार्ड १८९"},
    {"key": "ward_190", "nameEn": "Ward 190", "nameMr": "वार्ड १९०"},
    {"key": "ward_191", "nameEn": "Ward 191", "nameMr": "वार्ड १९१"},
    {"key": "ward_192", "nameEn": "Ward 192", "nameMr": "वार्ड १९२"},
    {"key": "ward_193", "nameEn": "Ward 193", "nameMr": "वार्ड १९३"},
    {"key": "ward_194", "nameEn": "Ward 194", "nameMr": "वार्ड १९४"},
    {"key": "ward_195", "nameEn": "Ward 195", "nameMr": "वार्ड १९५"},
    {"key": "ward_196", "nameEn": "Ward 196", "nameMr": "वार्ड १९६"},
    {"key": "ward_197", "nameEn": "Ward 197", "nameMr": "वार्ड १९७"},
    {"key": "ward_198", "nameEn": "Ward 198", "nameMr": "वार्ड १९८"},
    {"key": "ward_199", "nameEn": "Ward 199", "nameMr": "वार्ड १९९"},
    {"key": "ward_200", "nameEn": "Ward 200", "nameMr": "वार्ड २००"},
    {"key": "ward_201", "nameEn": "Ward 201", "nameMr": "वार्ड २०१"},
    {"key": "ward_202", "nameEn": "Ward 202", "nameMr": "वार्ड २०२"},
    {"key": "ward_203", "nameEn": "Ward 203", "nameMr": "वार्ड २०३"},
    {"key": "ward_204", "nameEn": "Ward 204", "nameMr": "वार्ड २०४"},
    {"key": "ward_205", "nameEn": "Ward 205", "nameMr": "वार्ड २०५"},
    {"key": "ward_206", "nameEn": "Ward 206", "nameMr": "वार्ड २०६"},
    {"key": "ward_207", "nameEn": "Ward 207", "nameMr": "वार्ड २०७"},
    {"key": "ward_208", "nameEn": "Ward 208", "nameMr": "वार्ड २०८"},
    {"key": "ward_209", "nameEn": "Ward 209", "nameMr": "वार्ड २०९"},
    {"key": "ward_210", "nameEn": "Ward 210", "nameMr": "वार्ड २१०"},
    {"key": "ward_211", "nameEn": "Ward 211", "nameMr": "वार्ड २११"},
    {"key": "ward_212", "nameEn": "Ward 212", "nameMr": "वार्ड २१२"},
    {"key": "ward_213", "nameEn": "Ward 213", "nameMr": "वार्ड २१३"},
    {"key": "ward_214", "nameEn": "Ward 214", "nameMr": "वार्ड २१४"},
    {"key": "ward_215", "nameEn": "Ward 215", "nameMr": "वार्ड २१५"},
    {"key": "ward_216", "nameEn": "Ward 216", "nameMr": "वार्ड २१६"},
    {"key": "ward_217", "nameEn": "Ward 217", "nameMr": "वार्ड २१७"},
    {"key": "ward_218", "nameEn": "Ward 218", "nameMr": "वार्ड २१८"},
    {"key": "ward_219", "nameEn": "Ward 219", "nameMr": "वार्ड २१९"},
    {"key": "ward_220", "nameEn": "Ward 220", "nameMr": "वार्ड २२०"},
    {"key": "ward_221", "nameEn": "Ward 221", "nameMr": "वार्ड २२१"},
    {"key": "ward_222", "nameEn": "Ward 222", "nameMr": "वार्ड २२२"},
    {"key": "ward_223", "nameEn": "Ward 223", "nameMr": "वार्ड २२३"},
    {"key": "ward_224", "nameEn": "Ward 224", "nameMr": "वार्ड २२४"},
    {"key": "ward_225", "nameEn": "Ward 225", "nameMr": "वार्ड २२५"},
    {"key": "ward_226", "nameEn": "Ward 226", "nameMr": "वार्ड २२६"},
    {"key": "ward_227", "nameEn": "Ward 227", "nameMr": "वार्ड २२७"},
    {"key": "ward_228", "nameEn": "Ward 228", "nameMr": "वार्ड २२८"},
    {"key": "ward_229", "nameEn": "Ward 229", "nameMr": "वार्ड २२९"},
    {"key": "ward_230", "nameEn": "Ward 230", "nameMr": "वार्ड २३०"},
    {"key": "ward_231", "nameEn": "Ward 231", "nameMr": "वार्ड २३१"},
    {"key": "ward_232", "nameEn": "Ward 232", "nameMr": "वार्ड २३२"},
    {"key": "ward_233", "nameEn": "Ward 233", "nameMr": "वार्ड २३३"},
    {"key": "ward_234", "nameEn": "Ward 234", "nameMr": "वार्ड २३४"},
    {"key": "ward_235", "nameEn": "Ward 235", "nameMr": "वार्ड २३५"},
    {"key": "ward_236", "nameEn": "Ward 236", "nameMr": "वार्ड २३६"},
    {"key": "ward_237", "nameEn": "Ward 237", "nameMr": "वार्ड २३७"},
    {"key": "ward_238", "nameEn": "Ward 238", "nameMr": "वार्ड २३८"},
    {"key": "ward_239", "nameEn": "Ward 239", "nameMr": "वार्ड २३९"},
    {"key": "ward_240", "nameEn": "Ward 240", "nameMr": "वार्ड २४०"},
    {"key": "ward_241", "nameEn": "Ward 241", "nameMr": "वार्ड २४१"},
    {"key": "ward_242", "nameEn": "Ward 242", "nameMr": "वार्ड २४२"},
    {"key": "ward_243", "nameEn": "Ward 243", "nameMr": "वार्ड २४३"},
    {"key": "ward_244", "nameEn": "Ward 244", "nameMr": "वार्ड २४४"},
    {"key": "ward_245", "nameEn": "Ward 245", "nameMr": "वार्ड २४५"},
    {"key": "ward_246", "nameEn": "Ward 246", "nameMr": "वार्ड २४६"},
    {"key": "ward_247", "nameEn": "Ward 247", "nameMr": "वार्ड २४७"},
    {"key": "ward_248", "nameEn": "Ward 248", "nameMr": "वार्ड २४८"},
    {"key": "ward_249", "nameEn": "Ward 249", "nameMr": "वार्ड २४९"},
    {"key": "ward_250", "nameEn": "Ward 250", "nameMr": "वार्ड २५०"},
    {"key": "ward_251", "nameEn": "Ward 251", "nameMr": "वार्ड २५१"},
    {"key": "ward_252", "nameEn": "Ward 252", "nameMr": "वार्ड २५२"},
    {"key": "ward_253", "nameEn": "Ward 253", "nameMr": "वार्ड २५३"},
    {"key": "ward_254", "nameEn": "Ward 254", "nameMr": "वार्ड २५४"},
    {"key": "ward_255", "nameEn": "Ward 255", "nameMr": "वार्ड २५५"},
    {"key": "ward_256", "nameEn": "Ward 256", "nameMr": "वार्ड २५६"},
    {"key": "ward_257", "nameEn": "Ward 257", "nameMr": "वार्ड २५७"},
    {"key": "ward_258", "nameEn": "Ward 258", "nameMr": "वार्ड २५८"},
    {"key": "ward_259", "nameEn": "Ward 259", "nameMr": "वार्ड २५९"},
    {"key": "ward_260", "nameEn": "Ward 260", "nameMr": "वार्ड २६०"},
    {"key": "ward_261", "nameEn": "Ward 261", "nameMr": "वार्ड २६१"},
    {"key": "ward_262", "nameEn": "Ward 262", "nameMr": "वार्ड २६२"},
    {"key": "ward_263", "nameEn": "Ward 263", "nameMr": "वार्ड २६३"},
    {"key": "ward_264", "nameEn": "Ward 264", "nameMr": "वार्ड २६४"},
    {"key": "ward_265", "nameEn": "Ward 265", "nameMr": "वार्ड २६५"},
    {"key": "ward_266", "nameEn": "Ward 266", "nameMr": "वार्ड २६६"},
    {"key": "ward_267", "nameEn": "Ward 267", "nameMr": "वार्ड २६७"},
    {"key": "ward_268", "nameEn": "Ward 268", "nameMr": "वार्ड २६८"},
    {"key": "ward_269", "nameEn": "Ward 269", "nameMr": "वार्ड २६९"},
    {"key": "ward_270", "nameEn": "Ward 270", "nameMr": "वार्ड २७०"},
    {"key": "ward_271", "nameEn": "Ward 271", "nameMr": "वार्ड २७१"},
    {"key": "ward_272", "nameEn": "Ward 272", "nameMr": "वार्ड २७२"},
    {"key": "ward_273", "nameEn": "Ward 273", "nameMr": "वार्ड २७३"},
    {"key": "ward_274", "nameEn": "Ward 274", "nameMr": "वार्ड २७४"},
    {"key": "ward_275", "nameEn": "Ward 275", "nameMr": "वार्ड २७५"},
    {"key": "ward_276", "nameEn": "Ward 276", "nameMr": "वार्ड २७६"},
    {"key": "ward_277", "nameEn": "Ward 277", "nameMr": "वार्ड २७७"},
    {"key": "ward_278", "nameEn": "Ward 278", "nameMr": "वार्ड २७८"},
    {"key": "ward_279", "nameEn": "Ward 279", "nameMr": "वार्ड २७९"},
    {"key": "ward_280", "nameEn": "Ward 280", "nameMr": "वार्ड २८०"},
    {"key": "ward_281", "nameEn": "Ward 281", "nameMr": "वार्ड २८१"},
    {"key": "ward_282", "nameEn": "Ward 282", "nameMr": "वार्ड २८२"},
    {"key": "ward_283", "nameEn": "Ward 283", "nameMr": "वार्ड २८३"},
    {"key": "ward_284", "nameEn": "Ward 284", "nameMr": "वार्ड २८४"},
    {"key": "ward_285", "nameEn": "Ward 285", "nameMr": "वार्ड २८५"},
    {"key": "ward_286", "nameEn": "Ward 286", "nameMr": "वार्ड २८६"},
    {"key": "ward_287", "nameEn": "Ward 287", "nameMr": "वार्ड २८७"},
    {"key": "ward_288", "nameEn": "Ward 288", "nameMr": "वार्ड २८८"},
    {"key": "ward_289", "nameEn": "Ward 289", "nameMr": "वार्ड २८९"},
    {"key": "ward_290", "nameEn": "Ward 290", "nameMr": "वार्ड २९०"},
    {"key": "ward_291", "nameEn": "Ward 291", "nameMr": "वार्ड २९१"},
    {"key": "ward_292", "nameEn": "Ward 292", "nameMr": "वार्ड २९२"},
    {"key": "ward_293", "nameEn": "Ward 293", "nameMr": "वार्ड २९३"},
    {"key": "ward_294", "nameEn": "Ward 294", "nameMr": "वार्ड २९४"},
    {"key": "ward_295", "nameEn": "Ward 295", "nameMr": "वार्ड २९५"},
    {"key": "ward_296", "nameEn": "Ward 296", "nameMr": "वार्ड २९६"},
    {"key": "ward_297", "nameEn": "Ward 297", "nameMr": "वार्ड २९७"},
    {"key": "ward_298", "nameEn": "Ward 298", "nameMr": "वार्ड २९८"},
    {"key": "ward_299", "nameEn": "Ward 299", "nameMr": "वार्ड २९९"},
    {"key": "ward_300", "nameEn": "Ward 300", "nameMr": "वार्ड ३००"}
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

  /// Talukas (Tehsils) in Maharashtra organized by district with multilingual support
  static const Map<String, List<Map<String, String>>> talukas = {
    "mumbai_city": [
      {"key": "colaba", "nameEn": "Colaba", "nameMr": "कोलाबा"},
      {"key": "fort", "nameEn": "Fort", "nameMr": "फोर्ट"},
      {"key": "andheri", "nameEn": "Andheri", "nameMr": "अंधेरी"},
      {"key": "borivali", "nameEn": "Borivali", "nameMr": "बोरिवली"},
      {"key": "kurla", "nameEn": "Kurla", "nameMr": "कुर्ला"},
      {"key": "chembur", "nameEn": "Chembur", "nameMr": "चेंबूर"},
      {"key": "bandra", "nameEn": "Bandra", "nameMr": "बांद्रा"},
      {"key": "dadar", "nameEn": "Dadar", "nameMr": "दादर"},
      {"key": "parel", "nameEn": "Parel", "nameMr": "पarel"},
      {"key": "worli", "nameEn": "Worli", "nameMr": "वोरली"}
    ],
    "mumbai_suburban": [
      {"key": "kandivali", "nameEn": "Kandivali", "nameMr": "कांदिवली"},
      {"key": "goregaon", "nameEn": "Goregaon", "nameMr": "गोरेगाव"},
      {"key": "malad", "nameEn": "Malad", "nameMr": "मालाड"},
      {"key": "mulund", "nameEn": "Mulund", "nameMr": "मुलुंड"},
      {"key": "vikhroli", "nameEn": "Vikhroli", "nameMr": "विक्रोळी"},
      {"key": "ghatkopar", "nameEn": "Ghatkopar", "nameMr": "घाटकोपर"},
      {"key": "powai", "nameEn": "Powai", "nameMr": "पवई"},
      {"key": "bhandup", "nameEn": "Bhandup", "nameMr": "भांडुप"}
    ],
    "thane": [
      {"key": "thane", "nameEn": "Thane", "nameMr": "ठाणे"},
      {"key": "kalyan", "nameEn": "Kalyan", "nameMr": "कल्याण"},
      {"key": "ulhasnagar", "nameEn": "Ulhasnagar", "nameMr": "उल्हासनगर"},
      {"key": "bhiwandi", "nameEn": "Bhiwandi", "nameMr": "भिवंडी"},
      {"key": "murbad", "nameEn": "Murbad", "nameMr": "मुरबाड"},
      {"key": "shahapur", "nameEn": "Shahapur", "nameMr": "शहापूर"},
      {"key": "ambernath", "nameEn": "Ambernath", "nameMr": "अंबरनाथ"},
      {"key": "dombivli", "nameEn": "Dombivli", "nameMr": "डोंबिवली"}
    ],
    "palghar": [
      {"key": "palghar", "nameEn": "Palghar", "nameMr": "पालघर"},
      {"key": "vasai", "nameEn": "Vasai", "nameMr": "वसई"},
      {"key": "virar", "nameEn": "Virar", "nameMr": "विरार"},
      {"key": "dahanu", "nameEn": "Dahanu", "nameMr": "डहाणू"},
      {"key": "talasari", "nameEn": "Talasari", "nameMr": "तलासरी"},
      {"key": "jawhar", "nameEn": "Jawhar", "nameMr": "जव्हार"},
      {"key": "mokhada", "nameEn": "Mokhada", "nameMr": "मोखाडा"},
      {"key": "vikramgad", "nameEn": "Vikramgad", "nameMr": "विक्रमगड"}
    ],
    "raigad": [
      {"key": "alibag", "nameEn": "Alibag", "nameMr": "अलीबाग"},
      {"key": "pen", "nameEn": "Pen", "nameMr": "पेण"},
      {"key": "murud", "nameEn": "Murud", "nameMr": "मुरुड"},
      {"key": "roha", "nameEn": "Roha", "nameMr": "रोहा"},
      {"key": "sudhagad", "nameEn": "Sudhagad", "nameMr": "सुधागड"},
      {"key": "mangaon", "nameEn": "Mangaon", "nameMr": "माणगाव"},
      {"key": "tala", "nameEn": "Tala", "nameMr": "तळा"},
      {"key": "shrivardhan", "nameEn": "Shrivardhan", "nameMr": "श्रीवर्धन"},
      {"key": "mahad", "nameEn": "Mahad", "nameMr": "महाड"},
      {"key": "poladpur", "nameEn": "Poladpur", "nameMr": "पोलादपूर"},
      {"key": "karjat", "nameEn": "Karjat", "nameMr": "कर्जत"},
      {"key": "khalapur", "nameEn": "Khalapur", "nameMr": "खालापूर"},
      {"key": "panvel", "nameEn": "Panvel", "nameMr": "पनवेल"},
      {"key": "uran", "nameEn": "Uran", "nameMr": "उरण"}
    ],
    "ratnagiri": [
      {"key": "ratnagiri", "nameEn": "Ratnagiri", "nameMr": "रत्नागिरी"},
      {"key": "chiplun", "nameEn": "Chiplun", "nameMr": "चिपळूण"},
      {"key": "sangameshwar", "nameEn": "Sangameshwar", "nameMr": "संगमेश्वर"},
      {"key": "lanja", "nameEn": "Lanja", "nameMr": "लांजा"},
      {"key": "rajapur", "nameEn": "Rajapur", "nameMr": "राजापूर"},
      {"key": "guhagar", "nameEn": "Guhagar", "nameMr": "गुहागर"},
      {"key": "dapur", "nameEn": "Dapoli", "nameMr": "दापोली"},
      {"key": "mandangad", "nameEn": "Mandangad", "nameMr": "मंडणगड"},
      {"key": "khed", "nameEn": "Khed", "nameMr": "खेड"}
    ],
    "sindhudurg": [
      {"key": "sawantwadi", "nameEn": "Sawantwadi", "nameMr": "सावंतवाडी"},
      {"key": "dodamarg", "nameEn": "Dodamarg", "nameMr": "दोडामार्ग"},
      {"key": "kudal", "nameEn": "Kudal", "nameMr": "कुडाळ"},
      {"key": "malvan", "nameEn": "Malvan", "nameMr": "मालवण"},
      {"key": "devgad", "nameEn": "Devgad", "nameMr": "देवगड"},
      {"key": "vaibhavwadi", "nameEn": "Vaibhavwadi", "nameMr": "वैभववाडी"},
      {"key": "kankavli", "nameEn": "Kankavli", "nameMr": "कणकवली"}
    ],
    "nashik": [
      {"key": "nashik", "nameEn": "Nashik", "nameMr": "नाशिक"},
      {"key": "sinnar", "nameEn": "Sinnar", "nameMr": "सिन्नर"},
      {"key": "niphad", "nameEn": "Niphad", "nameMr": "निफाड"},
      {"key": "dindori", "nameEn": "Dindori", "nameMr": "दिंडोरी"},
      {"key": "igATPuri", "nameEn": "IgATPuri", "nameMr": "इगतपुरी"},
      {"key": "trimbakeshwar", "nameEn": "Trimbakeshwar", "nameMr": "त्र्यंबकेश्वर"},
      {"key": "peint", "nameEn": "Peint", "nameMr": "पेईंट"},
      {"key": "surgana", "nameEn": "Surgana", "nameMr": "सुरगाणा"},
      {"key": "kalwan", "nameEn": "Kalwan", "nameMr": "कळवण"},
      {"key": "deola", "nameEn": "Deola", "nameMr": "देवळा"},
      {"key": "baglan", "nameEn": "Baglan", "nameMr": "बागलाण"},
      {"key": "malegaon", "nameEn": "Malegaon", "nameMr": "मालेगाव"},
      {"key": "nandgaon", "nameEn": "Nandgaon", "nameMr": "नांदगाव"},
      {"key": "chandwad", "nameEn": "Chandwad", "nameMr": "चांदवड"},
      {"key": "yeola", "nameEn": "Yeola", "nameMr": "येवला"}
    ],
    "dhule": [
      {"key": "dhule", "nameEn": "Dhule", "nameMr": "धुळे"},
      {"key": "sakri", "nameEn": "Sakri", "nameMr": "साक्री"},
      {"key": "shirpur", "nameEn": "Shirpur", "nameMr": "शिरपूर"},
      {"key": "shindkheda", "nameEn": "Shindkheda", "nameMr": "शिंदखेडा"}
    ],
    "jalgaon": [
      {"key": "jalgaon", "nameEn": "Jalgaon", "nameMr": "जळगाव"},
      {"key": "jamner", "nameEn": "Jamner", "nameMr": "जामनेर"},
      {"key": "erandol", "nameEn": "Erandol", "nameMr": "एरंडोल"},
      {"key": "dharangaon", "nameEn": "Dharangaon", "nameMr": "धरणगाव"},
      {"key": "bhusaWal", "nameEn": "Bhusawal", "nameMr": "भुसावळ"},
      {"key": "bodwad", "nameEn": "Bodwad", "nameMr": "बोदवड"},
      {"key": "yawal", "nameEn": "Yawal", "nameMr": "यावल"},
      {"key": "raver", "nameEn": "Raver", "nameMr": "रावेर"},
      {"key": "muktainagar", "nameEn": "Muktainagar", "nameMr": "मुक्ताईनगर"},
      {"key": "amAlner", "nameEn": "Amalner", "nameMr": "अमळनेर"},
      {"key": "parola", "nameEn": "Parola", "nameMr": "पारोळा"},
      {"key": "chopda", "nameEn": "Chopda", "nameMr": "चोपडा"},
      {"key": "pachora", "nameEn": "Pachora", "nameMr": "पाचोरा"},
      {"key": "bhadgaon", "nameEn": "Bhadgaon", "nameMr": "भडगाव"}
    ],
    "ahmednagar": [
      {"key": "ahmednagar", "nameEn": "Ahmednagar", "nameMr": "अहमदनगर"},
      {"key": "shevgaon", "nameEn": "Shevgaon", "nameMr": "शेवगाव"},
      {"key": "pathardi", "nameEn": "Pathardi", "nameMr": "पाथर्डी"},
      {"key": "nagar", "nameEn": "Nagar", "nameMr": "नगर"},
      {"key": "rahuri", "nameEn": "Rahuri", "nameMr": "राहुरी"},
      {"key": "shrirampur", "nameEn": "Shrirampur", "nameMr": "श्रीरामपूर"},
      {"key": "newasa", "nameEn": "Newasa", "nameMr": "नेवासा"},
      {"key": "jamkhed", "nameEn": "Jamkhed", "nameMr": "जामखेड"},
      {"key": "karjat", "nameEn": "Karjat", "nameMr": "कर्जत"},
      {"key": "shrigonda", "nameEn": "Shrigonda", "nameMr": "श्रीगोंदा"},
      {"key": "parner", "nameEn": "Parner", "nameMr": "पारनेर"},
      {"key": "akole", "nameEn": "Akole", "nameMr": "अकोले"},
      {"key": "sangamner", "nameEn": "Sangamner", "nameMr": "संगमनेर"},
      {"key": "kopargaon", "nameEn": "Kopargaon", "nameMr": "कोपरगाव"},
      {"key": "rahta", "nameEn": "Rahta", "nameMr": "राहता"}
    ],
    "nandurbar": [
      {"key": "nandurbar", "nameEn": "Nandurbar", "nameMr": "नंदुरबार"},
      {"key": "nawapur", "nameEn": "Nawapur", "nameMr": "नवापूर"},
      {"key": "taloda", "nameEn": "Taloda", "nameMr": "तळोदा"},
      {"key": "akkalkuwa", "nameEn": "Akkalkuwa", "nameMr": "अक्कलकुवा"},
      {"key": "dhadgaon", "nameEn": "Dhadgaon", "nameMr": "धडगाव"},
      {"key": "shahada", "nameEn": "Shahada", "nameMr": "शहादा"}
    ],
    "pune": [
      {"key": "pune_city", "nameEn": "Pune City", "nameMr": "पुणे शहर"},
      {"key": "haveli", "nameEn": "Haveli", "nameMr": "हवेली"},
      {"key": "mulshi", "nameEn": "Mulshi", "nameMr": "मुळशी"},
      {"key": "mawal", "nameEn": "Mawal", "nameMr": "मावळ"},
      {"key": "khed", "nameEn": "Khed", "nameMr": "खेड"},
      {"key": "junnar", "nameEn": "Junnar", "nameMr": "जुन्नर"},
      {"key": "ambegaon", "nameEn": "Ambegaon", "nameMr": "आंबेगाव"},
      {"key": "shirur", "nameEn": "Shirur", "nameMr": "शिरूर"},
      {"key": "daund", "nameEn": "Daund", "nameMr": "दौंड"},
      {"key": "purandar", "nameEn": "Purandar", "nameMr": "पुरंदर"},
      {"key": "velhe", "nameEn": "Velhe", "nameMr": "वेल्हे"},
      {"key": "bhor", "nameEn": "Bhor", "nameMr": "भोर"},
      {"key": "baramati", "nameEn": "Baramati", "nameMr": "बारामती"},
      {"key": "indapur", "nameEn": "Indapur", "nameMr": "इंदापूर"}
    ],
    "satara": [
      {"key": "satara", "nameEn": "Satara", "nameMr": "सातारा"},
      {"key": "koregaon", "nameEn": "Koregaon", "nameMr": "कोरेगाव"},
      {"key": "karad", "nameEn": "Karad", "nameMr": "कराड"},
      {"key": "patan", "nameEn": "Patan", "nameMr": "पाटण"},
      {"key": "jaoli", "nameEn": "Jaoli", "nameMr": "जावली"},
      {"key": "mahabaleshwar", "nameEn": "Mahabaleshwar", "nameMr": "महाबळेश्वर"},
      {"key": "wai", "nameEn": "Wai", "nameMr": "वाई"},
      {"key": "khandala", "nameEn": "Khandala", "nameMr": "खंडाळा"},
      {"key": "phaltan", "nameEn": "Phaltan", "nameMr": "फलटण"},
      {"key": "man", "nameEn": "Man", "nameMr": "माण"},
      {"key": "khatav", "nameEn": "Khatav", "nameMr": "खटाव"}
    ],
    "sangli": [
      {"key": "sangli", "nameEn": "Sangli", "nameMr": "सांगली"},
      {"key": "miraj", "nameEn": "Miraj", "nameMr": "मिरज"},
      {"key": "tasgaon", "nameEn": "Tasgaon", "nameMr": "तासगाव"},
      {"key": "jath", "nameEn": "Jath", "nameMr": "जत"},
      {"key": "kavathe_mahankal", "nameEn": "Kavathe Mahankal", "nameMr": "कवठे महांकाळ"},
      {"key": "atpadi", "nameEn": "Atpadi", "nameMr": "आटपाडी"},
      {"key": "palus", "nameEn": "Palus", "nameMr": "पलूस"},
      {"key": "kadegaon", "nameEn": "Kadegaon", "nameMr": "कडेगाव"},
      {"key": "valva", "nameEn": "Walva", "nameMr": "वाळवा"},
      {"key": "shirala", "nameEn": "Shirala", "nameMr": "शिराळा"}
    ],
    "solapur": [
      {"key": "solapur_north", "nameEn": "Solapur North", "nameMr": "सोलापूर उत्तर"},
      {"key": "solapur_south", "nameEn": "Solapur South", "nameMr": "सोलापूर दक्षिण"},
      {"key": "akkalkot", "nameEn": "Akkalkot", "nameMr": "अक्कलकोट"},
      {"key": "barshi", "nameEn": "Barshi", "nameMr": "बार्शी"},
      {"key": "madha", "nameEn": "Madha", "nameMr": "माढा"},
      {"key": "karmala", "nameEn": "Karmala", "nameMr": "करमाळा"},
      {"key": "pandharpur", "nameEn": "Pandharpur", "nameMr": "पंढरपूर"},
      {"key": "malshiras", "nameEn": "Malshiras", "nameMr": "माळशिरस"},
      {"key": "sangola", "nameEn": "Sangola", "nameMr": "सांगोला"},
      {"key": "mangalvedhe", "nameEn": "Mangalvedhe", "nameMr": "मंगळवेढे"},
      {"key": "mohol", "nameEn": "Mohol", "nameMr": "मोहोळ"}
    ],
    "kolhapur": [
      {"key": "kolhapur", "nameEn": "Kolhapur", "nameMr": "कोल्हापूर"},
      {"key": "karvir", "nameEn": "Karvir", "nameMr": "करवीर"},
      {"key": "panhala", "nameEn": "Panhala", "nameMr": "पन्हाळा"},
      {"key": "shahuwadi", "nameEn": "Shahuwadi", "nameMr": "शाहूवाडी"},
      {"key": "kagal", "nameEn": "Kagal", "nameMr": "कागल"},
      {"key": "hatkanangle", "nameEn": "Hatkanangle", "nameMr": "हातकणंगले"},
      {"key": "shirol", "nameEn": "Shirol", "nameMr": "शिरोळ"},
      {"key": "radhanagari", "nameEn": "Radhanagari", "nameMr": "राधानगरी"},
      {"key": "gaganbavada", "nameEn": "Gaganbavada", "nameMr": "गगनबावडा"},
      {"key": "bhudargad", "nameEn": "Bhudargad", "nameMr": "भुदरगड"},
      {"key": "ajra", "nameEn": "Ajra", "nameMr": "आजरा"},
      {"key": "gadhinglaj", "nameEn": "Gadhinglaj", "nameMr": "गडहिंग्लज"}
    ],
    "aurangabad": [
      {"key": "aurangabad", "nameEn": "Aurangabad", "nameMr": "औरंगाबाद"},
      {"key": "kannad", "nameEn": "Kannad", "nameMr": "कन्नड"},
      {"key": "soegaon", "nameEn": "Soegaon", "nameMr": "सोयगाव"},
      {"key": "sillod", "nameEn": "Sillod", "nameMr": "सिल्लोड"},
      {"key": "phulambri", "nameEn": "Phulambri", "nameMr": "फुलंब्री"},
      {"key": "khuldabad", "nameEn": "Khuldabad", "nameMr": "खुल्दाबाद"},
      {"key": "vaijapur", "nameEn": "Vaijapur", "nameMr": "वैजापूर"},
      {"key": "gangapur", "nameEn": "Gangapur", "nameMr": "गंगापूर"},
      {"key": "paithan", "nameEn": "Paithan", "nameMr": "पैठण"}
    ],
    "jalna": [
      {"key": "jalna", "nameEn": "Jalna", "nameMr": "जालना"},
      {"key": "ambad", "nameEn": "Ambad", "nameMr": "आंबड"},
      {"key": "ghansawangi", "nameEn": "Ghansawangi", "nameMr": "घनसावंगी"},
      {"key": "partur", "nameEn": "Partur", "nameMr": "परतूर"},
      {"key": "mantha", "nameEn": "Mantha", "nameMr": "मंठा"},
      {"key": "bhokardan", "nameEn": "Bhokardan", "nameMr": "भोकरदन"},
      {"key": "jafrabad", "nameEn": "Jafrabad", "nameMr": "जाफराबाद"},
      {"key": "badnapur", "nameEn": "Badnapur", "nameMr": "बदनापूर"}
    ],
    "parbhani": [
      {"key": "parbhani", "nameEn": "Parbhani", "nameMr": "परभणी"},
      {"key": "gangakhed", "nameEn": "Gangakhed", "nameMr": "गंगाखेड"},
      {"key": "pathri", "nameEn": "Pathri", "nameMr": "पाथरी"},
      {"key": "sonpeth", "nameEn": "Sonpeth", "nameMr": "सोनपेठ"},
      {"key": "palam", "nameEn": "Palam", "nameMr": "पाळम"},
      {"key": "purna", "nameEn": "Purna", "nameMr": "पूर्णा"},
      {"key": "manwath", "nameEn": "Manwath", "nameMr": "मंवत"},
      {"key": "selu", "nameEn": "Selu", "nameMr": "सेलू"},
      {"key": "jintur", "nameEn": "Jintur", "nameMr": "जिंतूर"}
    ],
    "hingoli": [
      {"key": "hingoli", "nameEn": "Hingoli", "nameMr": "हिंगोली"},
      {"key": "sengaon", "nameEn": "Sengaon", "nameMr": "सेनगाव"},
      {"key": "kalmnuri", "nameEn": "Kalamnuri", "nameMr": "कळमनुरी"},
      {"key": "basmath", "nameEn": "Basmath", "nameMr": "बसमत"},
      {"key": "aundha_nagnath", "nameEn": "Aundha Nagnath", "nameMr": "औंढा नागनाथ"}
    ],
    "nanded": [
      {"key": "nanded", "nameEn": "Nanded", "nameMr": "नांदेड"},
      {"key": "ardhapuri", "nameEn": "Ardhapuri", "nameMr": "अर्धापुरी"},
      {"key": "mudkhed", "nameEn": "Mudkhed", "nameMr": "मुदखेड"},
      {"key": "bhokar", "nameEn": "Bhokar", "nameMr": "भोकर"},
      {"key": "umri", "nameEn": "Umri", "nameMr": "उमरी"},
      {"key": "mahoor", "nameEn": "Mahur", "nameMr": "माहूर"},
      {"key": "kinwat", "nameEn": "Kinwat", "nameMr": "किनवट"},
      {"key": "himayatnagar", "nameEn": "Himayatnagar", "nameMr": "हिमायतनगर"},
      {"key": "hadgaon", "nameEn": "Hadgaon", "nameMr": "हदगाव"},
      {"key": "loha", "nameEn": "Loha", "nameMr": "लोहा"},
      {"key": "kandhar", "nameEn": "Kandhar", "nameMr": "कंधार"},
      {"key": "mukhed", "nameEn": "Mukhed", "nameMr": "मुखेड"},
      {"key": "degloor", "nameEn": "Degloor", "nameMr": "देगलूर"},
      {"key": "biloli", "nameEn": "Biloli", "nameMr": "बिलोली"},
      {"key": "dharmabad", "nameEn": "Dharmabad", "nameMr": "धर्माबाद"},
      {"key": "naigaon", "nameEn": "Naigaon", "nameMr": "नायगाव"}
    ],
    "latur": [
      {"key": "latur", "nameEn": "Latur", "nameMr": "लातूर"},
      {"key": "renapur", "nameEn": "Renapur", "nameMr": "रेनापूर"},
      {"key": "ahmedpur", "nameEn": "Ahmedpur", "nameMr": "अहमदपूर"},
      {"key": "jalkot", "nameEn": "Jalkot", "nameMr": "जळकोट"},
      {"key": "chakur", "nameEn": "Chakur", "nameMr": "चाकूर"},
      {"key": "shirur_anantpal", "nameEn": "Shirur Anantpal", "nameMr": "शिरूर अनंतपाळ"},
      {"key": "ausa", "nameEn": "Ausa", "nameMr": "औसा"},
      {"key": "nilanga", "nameEn": "Nilanga", "nameMr": "निलंगा"},
      {"key": "devani", "nameEn": "Devani", "nameMr": "देवणी"},
      {"key": "udgir", "nameEn": "Udgir", "nameMr": "उदगीर"}
    ],
    "osmanabad": [
      {"key": "osmanabad", "nameEn": "Osmanabad", "nameMr": "उस्मानाबाद"},
      {"key": "paranda", "nameEn": "Paranda", "nameMr": "परंडा"},
      {"key": "bhum", "nameEn": "Bhum", "nameMr": "भूम"},
      {"key": "wash", "nameEn": "Wash", "nameMr": "वाशी"},
      {"key": "kalamb", "nameEn": "Kalamb", "nameMr": "कळंब"},
      {"key": "tuljapur", "nameEn": "Tuljapur", "nameMr": "तुळजापूर"},
      {"key": "omerga", "nameEn": "Omerga", "nameMr": "उमरगा"},
      {"key": "lohara", "nameEn": "Lohara", "nameMr": "लोहारा"}
    ],
    "beed": [
      {"key": "beed", "nameEn": "Beed", "nameMr": "बीड"},
      {"key": "ashti", "nameEn": "Ashti", "nameMr": "आष्टी"},
      {"key": "patoda", "nameEn": "Patoda", "nameMr": "पाटोदा"},
      {"key": "shirur_kasar", "nameEn": "Shirur Kasar", "nameMr": "शिरूर कासार"},
      {"key": "georai", "nameEn": "Georai", "nameMr": "गेवराई"},
      {"key": "majalgaon", "nameEn": "Majalgaon", "nameMr": "माजलगाव"},
      {"key": "wadwani", "nameEn": "Wadwani", "nameMr": "वडवणी"},
      {"key": "kaij", "nameEn": "Kaij", "nameMr": "केज"},
      {"key": "dharur", "nameEn": "Dharur", "nameMr": "धरूर"},
      {"key": "parli", "nameEn": "Parli", "nameMr": "पारळी"},
      {"key": "ambajogai", "nameEn": "Ambajogai", "nameMr": "अंबाजोगाई"}
    ],
    "akola": [
      {"key": "akola", "nameEn": "Akola", "nameMr": "अकोला"},
      {"key": "akot", "nameEn": "Akot", "nameMr": "अकोट"},
      {"key": "telhara", "nameEn": "Telhara", "nameMr": "तेल्हारा"},
      {"key": "balapur", "nameEn": "Balapur", "nameMr": "बाळापूर"},
      {"key": "patur", "nameEn": "Patur", "nameMr": "पातूर"},
      {"key": "murtajapur", "nameEn": "Murtijapur", "nameMr": "मूर्तिजापूर"},
      {"key": "barshitakli", "nameEn": "Barshitakli", "nameMr": "बार्शीटाकळी"}
    ],
    "amravati": [
      {"key": "amravati", "nameEn": "Amravati", "nameMr": "अमरावती"},
      {"key": "bhatkuli", "nameEn": "Bhatkuli", "nameMr": "भातकुली"},
      {"key": "daryapur", "nameEn": "Daryapur", "nameMr": "दर्यापूर"},
      {"key": "nandgaon_khandeshwar", "nameEn": "Nandgaon Khandeshwar", "nameMr": "नांदगाव खंडेश्वर"},
      {"key": "dharni", "nameEn": "Dharni", "nameMr": "धरणी"},
      {"key": "chikhaldara", "nameEn": "Chikhaldara", "nameMr": "चिखलदरा"},
      {"key": "achlapur", "nameEn": "Achalpur", "nameMr": "अचलपूर"},
      {"key": "chandur_bazar", "nameEn": "Chandur Bazar", "nameMr": "चांदूर बाजार"},
      {"key": "morshi", "nameEn": "Morshi", "nameMr": "मोर्शी"},
      {"key": "warud", "nameEn": "Warud", "nameMr": "वरुड"},
      {"key": "tiwasa", "nameEn": "Tiwasa", "nameMr": "तिवसा"},
      {"key": "anjanGaon_surji", "nameEn": "Anjangaon Surji", "nameMr": "अंजनगाव सुर्जी"},
      {"key": "chandur_railway", "nameEn": "Chandur Railway", "nameMr": "चांदूर रेल्वे"},
      {"key": "dhamangaon_railway", "nameEn": "Dhamangaon Railway", "nameMr": "धामणगाव रेल्वे"}
    ],
    "buldhana": [
      {"key": "buldhana", "nameEn": "Buldhana", "nameMr": "बुलढाणा"},
      {"key": "chikhli", "nameEn": "Chikhli", "nameMr": "चिखली"},
      {"key": "deulgaon_raja", "nameEn": "Deulgaon Raja", "nameMr": "देऊळगाव राजा"},
      {"key": "jalgaon_jamod", "nameEn": "Jalgaon Jamod", "nameMr": "जळगाव जामोद"},
      {"key": "sangrampur", "nameEn": "Sangrampur", "nameMr": "संग्रामपूर"},
      {"key": "malkapur", "nameEn": "Malkapur", "nameMr": "मलकापूर"},
      {"key": "motala", "nameEn": "Motala", "nameMr": "मोताळा"},
      {"key": "nandura", "nameEn": "Nandura", "nameMr": "नांदुरा"},
      {"key": "khamgaon", "nameEn": "Khamgaon", "nameMr": "खामगाव"},
      {"key": "shegaon", "nameEn": "Shegaon", "nameMr": "शेगाव"},
      {"key": "mehkar", "nameEn": "Mehkar", "nameMr": "मेहकर"},
      {"key": "lonar", "nameEn": "Lonar", "nameMr": "लोणार"},
      {"key": "sindkhed_raja", "nameEn": "Sindkhed Raja", "nameMr": "सिंदखेड राजा"}
    ],
    "washim": [
      {"key": "washim", "nameEn": "Washim", "nameMr": "वाशिम"},
      {"key": "malegaon", "nameEn": "Malegaon", "nameMr": "मालेगाव"},
      {"key": "risod", "nameEn": "Risod", "nameMr": "रिसोड"},
      {"key": "mangrulpir", "nameEn": "Mangrulpir", "nameMr": "मंगरूळपीर"},
      {"key": "karanja", "nameEn": "Karanja", "nameMr": "करंजा"},
      {"key": "manora", "nameEn": "Manora", "nameMr": "मानोरा"}
    ],
    "yavatmal": [
      {"key": "yavatmal", "nameEn": "Yavatmal", "nameMr": "यवतमाळ"},
      {"key": "arNi", "nameEn": "Arni", "nameMr": "अर्णी"},
      {"key": "babulgaon", "nameEn": "Babulgaon", "nameMr": "बाभूळगाव"},
      {"key": "kalamb", "nameEn": "Kalamb", "nameMr": "कळंब"},
      {"key": "darwha", "nameEn": "Darwha", "nameMr": "दारव्हा"},
      {"key": "digras", "nameEn": "Digras", "nameMr": "डिग्रस"},
      {"key": "ner", "nameEn": "Ner", "nameMr": "नेर"},
      {"key": "p Pusad", "nameEn": "Pusad", "nameMr": "पुसद"},
      {"key": "umarkhed", "nameEn": "Umarkhed", "nameMr": "उमरखेड"},
      {"key": "mahad", "nameEn": "Mahagaon", "nameMr": "महागाव"},
      {"key": "kelapur", "nameEn": "Kelapur", "nameMr": "केलापूर"},
      {"key": "ralegaon", "nameEn": "Ralegaon", "nameMr": "रालेगाव"},
      {"key": "ghatanji", "nameEn": "Ghatanji", "nameMr": "घाटंजी"},
      {"key": "wani", "nameEn": "Wani", "nameMr": "वणी"},
      {"key": "maregaon", "nameEn": "Maregaon", "nameMr": "मारेगाव"},
      {"key": "zari_jamani", "nameEn": "Zari Jamani", "nameMr": "झरी जमणी"}
    ],
    "nagpur": [
      {"key": "nagpur_urban", "nameEn": "Nagpur Urban", "nameMr": "नागपूर शहरी"},
      {"key": "nagpur_rural", "nameEn": "Nagpur Rural", "nameMr": "नागपूर ग्रामीण"},
      {"key": "hingna", "nameEn": "Hingna", "nameMr": "हिंगणा"},
      {"key": "umred", "nameEn": "Umred", "nameMr": "उमरेड"},
      {"key": "kuhi", "nameEn": "Kuhi", "nameMr": "कुही"},
      {"key": "kamthi", "nameEn": "Kamthi", "nameMr": "कामठी"},
      {"key": "savner", "nameEn": "Savner", "nameMr": "सावनेर"},
      {"key": "parseoni", "nameEn": "Parseoni", "nameMr": "पारशिवणी"},
      {"key": "ramtek", "nameEn": "Ramtek", "nameMr": "रामटेक"},
      {"key": "mouda", "nameEn": "Mouda", "nameMr": "मौदा"},
      {"key": "bhiwapur", "nameEn": "Bhiwapur", "nameMr": "भिवापूर"},
      {"key": "kalmeshwar", "nameEn": "Kalmeshwar", "nameMr": "कळमेश्वर"},
      {"key": "katol", "nameEn": "Katol", "nameMr": "काटोल"},
      {"key": "narkhed", "nameEn": "Narkhed", "nameMr": "नरखेड"}
    ],
    "wardha": [
      {"key": "wardha", "nameEn": "Wardha", "nameMr": "वर्धा"},
      {"key": "ashti", "nameEn": "Ashti", "nameMr": "आष्टी"},
      {"key": "karanja", "nameEn": "Karanja", "nameMr": "करंजा"},
      {"key": "arvi", "nameEn": "Arvi", "nameMr": "आर्वी"},
      {"key": "seloo", "nameEn": "Seloo", "nameMr": "सेलू"},
      {"key": "deoli", "nameEn": "Deoli", "nameMr": "देवली"},
      {"key": "higanghat", "nameEn": "Hinganghat", "nameMr": "हिंगणघाट"},
      {"key": "samudrapur", "nameEn": "Samudrapur", "nameMr": "समुद्रपूर"}
    ],
    "bhandara": [
      {"key": "bhandara", "nameEn": "Bhandara", "nameMr": "भंडारा"},
      {"key": "tumsar", "nameEn": "Tumsar", "nameMr": "तुमसर"},
      {"key": "pauni", "nameEn": "Pauni", "nameMr": "पवनी"},
      {"key": "mohadi", "nameEn": "Mohadi", "nameMr": "मोहाडी"},
      {"key": "sakoli", "nameEn": "Sakoli", "nameMr": "साकोली"},
      {"key": "lakhandur", "nameEn": "Lakhandur", "nameMr": "लाखांदूर"},
      {"key": "lakhani", "nameEn": "Lakhani", "nameMr": "लाखणी"}
    ],
    "gondia": [
      {"key": "gondia", "nameEn": "Gondia", "nameMr": "गोंदिया"},
      {"key": "tirora", "nameEn": "Tirora", "nameMr": "तिरोडा"},
      {"key": "goregaon", "nameEn": "Goregaon", "nameMr": "गोरेगाव"},
      {"key": "amgaon", "nameEn": "Amgaon", "nameMr": "आमगाव"},
      {"key": "salekasa", "nameEn": "Salekasa", "nameMr": "सालेकसा"},
      {"key": "sadak_arjuni", "nameEn": "Sadak Arjuni", "nameMr": "सडक अर्जुनी"},
      {"key": "deori", "nameEn": "Deori", "nameMr": "देवरी"},
      {"key": "arjunimorgaon", "nameEn": "Arjuni Morgaon", "nameMr": "अर्जुनी मोरगाव"}
    ],
    "chandrapur": [
      {"key": "chandrapur", "nameEn": "Chandrapur", "nameMr": "चंद्रपूर"},
      {"key": "ballarpur", "nameEn": "Ballarpur", "nameMr": "बल्लारपूर"},
      {"key": "warora", "nameEn": "Warora", "nameMr": "वरोरा"},
      {"key": "chimur", "nameEn": "Chimur", "nameMr": "चिमूर"},
      {"key": "bhadravati", "nameEn": "Bhadravati", "nameMr": "भद्रावती"},
      {"key": "brahmapuri", "nameEn": "Brahmapuri", "nameMr": "ब्रह्मपुरी"},
      {"key": "nagbhir", "nameEn": "Nagbhir", "nameMr": "नागभीड"},
      {"key": "sindewahi", "nameEn": "Sindewahi", "nameMr": "सिंदेवाही"},
      {"key": "mul", "nameEn": "Mul", "nameMr": "मुल"},
      {"key": "pombhurna", "nameEn": "Pombhurna", "nameMr": "पोंभूर्णा"},
      {"key": "sawali", "nameEn": "Sawali", "nameMr": "सावली"},
      {"key": "rajura", "nameEn": "Rajura", "nameMr": "राजुरा"},
      {"key": "korpana", "nameEn": "Korpana", "nameMr": "कोरपना"},
      {"key": "jivti", "nameEn": "Jivti", "nameMr": "जिवती"},
      {"key": "gondpimpri", "nameEn": "Gondpimpri", "nameMr": "गोंडपिंपरी"}
    ],
    "gadchiroli": [
      {"key": "gadchiroli", "nameEn": "Gadchiroli", "nameMr": "गडचिरोली"},
      {"key": "desaiganj", "nameEn": "Desaiganj", "nameMr": "देसाईगंज"},
      {"key": "armori", "nameEn": "Armori", "nameMr": "आर्मोरी"},
      {"key": "chamorshi", "nameEn": "Chamorshi", "nameMr": "चामोर्शी"},
      {"key": "mulchera", "nameEn": "Mulchera", "nameMr": "मुलचेरा"},
      {"key": "etapalli", "nameEn": "Etapalli", "nameMr": "एटापल्ली"},
      {"key": "bhamragad", "nameEn": "Bhamragad", "nameMr": "भामरागड"},
      {"key": "aheri", "nameEn": "Aheri", "nameMr": "आहेरी"},
      {"key": "sironcha", "nameEn": "Sironcha", "nameMr": "सिरोंचा"},
      {"key": "dhanora", "nameEn": "Dhanora", "nameMr": "धानोरा"},
      {"key": "kurkheda", "nameEn": "Kurkheda", "nameMr": "कुरखेडा"},
      {"key": "korchi", "nameEn": "Korchi", "nameMr": "कोरची"}
    ]
  };

  // ===== TALUKA METHODS =====

  /// Get taluka display name by district key and taluka key with locale support
  static String getTalukaDisplayName(String districtKey, String talukaKey, String locale) {
    if (!talukas.containsKey(districtKey)) return talukaKey;

    final districtTalukas = talukas[districtKey]!;
    final taluka = districtTalukas.firstWhere(
      (t) => t['key'] == talukaKey,
      orElse: () => {'nameEn': talukaKey, 'nameMr': talukaKey},
    );

    return locale == 'mr' ? taluka['nameMr']! : taluka['nameEn']!;
  }

  /// Get taluka display name with automatic locale detection
  static String getTalukaDisplayNameWithLocale(String districtKey, String talukaKey) {
    return getTalukaDisplayName(districtKey, talukaKey, _getCurrentLocale());
  }

  /// Get all talukas for a specific district
  static List<Map<String, String>> getTalukasByDistrict(String districtKey) {
    return talukas[districtKey] ?? [];
  }

  /// Search talukas across all districts
  static List<Map<String, String>> searchTalukas(String query) {
    if (query.isEmpty) return [];

    final results = <Map<String, String>>[];
    final lowerQuery = query.toLowerCase();

    talukas.forEach((districtKey, districtTalukas) {
      for (final taluka in districtTalukas) {
        final nameEn = taluka['nameEn']!.toLowerCase();
        final nameMr = taluka['nameMr']!.toLowerCase();

        if (nameEn.contains(lowerQuery) || nameMr.contains(lowerQuery)) {
          results.add({
            'key': taluka['key']!,
            'nameEn': taluka['nameEn']!,
            'nameMr': taluka['nameMr']!,
            'districtKey': districtKey,
          });
        }
      }
    });

    return results;
  }

  /// Search talukas within a specific district
  static List<Map<String, String>> searchTalukasInDistrict(String districtKey, String query) {
    if (query.isEmpty) return getTalukasByDistrict(districtKey);

    final districtTalukas = getTalukasByDistrict(districtKey);
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, String>>[];

    for (final taluka in districtTalukas) {
      final nameEn = taluka['nameEn']!.toLowerCase();
      final nameMr = taluka['nameMr']!.toLowerCase();

      if (nameEn.contains(lowerQuery) || nameMr.contains(lowerQuery)) {
        results.add(taluka);
      }
    }

    return results;
  }

  /// Get taluka key from display name
  static String? getTalukaKeyFromName(String districtKey, String displayName) {
    final districtTalukas = getTalukasByDistrict(districtKey);

    for (final taluka in districtTalukas) {
      if (taluka['nameEn'] == displayName || taluka['nameMr'] == displayName) {
        return taluka['key'];
      }
    }

    return null;
  }

  /// Get all taluka keys for a district
  static List<String> getTalukaKeysByDistrict(String districtKey) {
    return getTalukasByDistrict(districtKey).map((t) => t['key']!).toList();
  }

  /// Get taluka count for a district
  static int getTalukaCount(String districtKey) {
    return getTalukasByDistrict(districtKey).length;
  }

  /// Check if a taluka exists in a district
  static bool talukaExists(String districtKey, String talukaKey) {
    final districtTalukas = getTalukasByDistrict(districtKey);
    return districtTalukas.any((t) => t['key'] == talukaKey);
  }

  /// Get current locale from context (helper method)
  static String _getCurrentLocale() {
    // This method should be called from within a Flutter widget context
    // For now, return default 'en' - override in calling code with actual locale
    return 'en';
  }

  /// Get all districts that have taluka data
  static List<String> getDistrictsWithTalukas() {
    return talukas.keys.toList();
  }

  /// Get taluka statistics
  static Map<String, dynamic> getTalukaStatistics() {
    int totalTalukas = 0;
    int districtsWithTalukas = talukas.length;

    talukas.forEach((districtKey, districtTalukas) {
      totalTalukas += districtTalukas.length;
    });

    return {
      'totalDistricts': districtsWithTalukas,
      'totalTalukas': totalTalukas,
      'averageTalukasPerDistrict': (totalTalukas / districtsWithTalukas).round(),
    };
  }

  // ===== DISTRICT METHODS =====

  /// Get district by key
  static Map<String, String>? getDistrictByKey(String key) {
    try {
      return districts.firstWhere(
        (district) => district['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      debugPrint('Error finding district by key $key: $e');
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
      debugPrint('Error finding ward by key $key: $e');
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
      debugPrint('Error parsing ward number from key $key: $e');
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
      debugPrint('Error finding local body type by key $key: $e');
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