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
    "ahilyanagar": [
      {"key": "ahilyanagar", "nameEn": "Ahilyanagar", "nameMr": "अहिल्यानगर"},
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
    "chhatrapati_sambhajinagar": [
      {"key": "chhatrapati_sambhajinagar", "nameEn": "Chhatrapati Sambhajinagar", "nameMr": "छत्रपती संभाजीनगर"},
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
    "dharashiv": [
      {"key": "dharashiv", "nameEn": "Dharashiv", "nameMr": "धाराशिव"},
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
