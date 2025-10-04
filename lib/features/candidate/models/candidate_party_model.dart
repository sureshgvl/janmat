class Party {
  final String id;
  final String name;
  final String nameMr; // Marathi name
  final String abbreviation;
  final String? symbolPath;
  final bool isActive;

  Party({
    required this.id,
    required this.name,
    required this.nameMr,
    required this.abbreviation,
    this.symbolPath,
    this.isActive = true,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameMr: json['name_mr'] ?? '',
      abbreviation: json['abbreviation'] ?? '',
      symbolPath: json['symbolPath'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_mr': nameMr,
      'abbreviation': abbreviation,
      'symbolPath': symbolPath,
      'isActive': isActive,
    };
  }

  // Get display name based on current locale
  String getDisplayName(String locale) {
    // Use localized strings instead of static nameMr field
    switch (id) {
      case 'bjp':
        return locale == 'mr' ? 'भारतीय जनता पक्ष' : 'Bharatiya Janata Party';
      case 'inc':
        return locale == 'mr'
            ? 'भारतीय राष्ट्रीय काँग्रेस'
            : 'Indian National Congress';
      case 'shiv_sena_ubt':
        return locale == 'mr'
            ? 'शिवसेना (उद्धव बाळासाहेब ठाकरे)'
            : 'Shiv Sena (Uddhav Balasaheb Thackeray)';
      case 'shiv_sena_shinde':
        return locale == 'mr'
            ? 'बाळासाहेबांची शिवसेना (शिंदे)'
            : 'Balasahebanchi Shiv Sena (Shinde)';
      case 'ncp_ajit':
        return locale == 'mr'
            ? 'राष्ट्रवादी काँग्रेस पक्ष (अजित पवार)'
            : 'Nationalist Congress Party (Ajit Pawar)';
      case 'ncp_sp':
        return locale == 'mr'
            ? 'राष्ट्रवादी काँग्रेस पक्ष (शरद पवार)'
            : 'Nationalist Congress Party (Sharad Pawar)';
      case 'mns':
        return locale == 'mr'
            ? 'महाराष्ट्र नवनिर्माण सेना'
            : 'Maharashtra Navnirman Sena';
      case 'cpi':
        return locale == 'mr'
            ? 'भारतीय कम्युनिस्ट पक्ष'
            : 'Communist Party of India';
      case 'cpi_m':
        return locale == 'mr'
            ? 'भारतीय कम्युनिस्ट पक्ष (मार्क्सवादी)'
            : 'Communist Party of India (Marxist)';
      case 'bsp':
        return locale == 'mr' ? 'बहुजन समाज पार्टी' : 'Bahujan Samaj Party';
      case 'sp':
        return locale == 'mr' ? 'समाजवादी पक्ष' : 'Samajwadi Party';
      case 'aimim':
        return locale == 'mr'
            ? 'ऑल इंडिया मजलिस-ए-इत्तेहादुल मुस्लिमीन'
            : 'All India Majlis-e-Ittehad-ul-Muslimeen';
      case 'npp':
        return locale == 'mr'
            ? 'राष्ट्रीय लोक पार्टी'
            : 'National Peoples Party';
      case 'pwpi':
        return locale == 'mr'
            ? 'शेतकरी कामगार पक्ष'
            : 'Peasants and Workers Party of India';
      case 'vba':
        return locale == 'mr' ? 'वंचित बहुजन आघाडी' : 'Vanchit Bahujan Aghadi';
      case 'rsp':
        return locale == 'mr'
            ? 'राष्ट्रीय समाज पक्ष'
            : 'Rashtriya Samaj Paksha';
      case 'bva':
        return locale == 'mr' ? 'बहुजन विकास आघाडी' : 'Bahujan Vikas Aaghadi';
      case 'abs':
        return locale == 'mr' ? 'अखिल भारतीय सेना' : 'Akhil Bharatiya Sena';
      case 'independent':
        return locale == 'mr' ? 'अपक्ष' : 'Independent';
      default:
        return name; // Fallback to original name
    }
  }
}

