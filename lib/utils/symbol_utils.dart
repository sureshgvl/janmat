import 'package:flutter/material.dart';
import '../features/candidate/models/candidate_model.dart';
import '../features/candidate/models/candidate_party_model.dart';

/// Centralized utility for party symbol path resolution
/// Optimized to avoid redundant function calls and computations
class SymbolUtils {
  // Cache for symbol paths to avoid repeated computations
  static final Map<String, String> _symbolCache = {};

  /// Comprehensive party data with multilingual support
  static const List<Map<String, String>> parties = [
    {
      "key": "inc",
      "shortNameEn": "INC",
      "shortNameMr": "कॉंग्रेस",
      "nameEn": "Indian National Congress",
      "nameMr": "इंडियन नॅशनल कॉंग्रेस",
      "image": "inc.png",
      "party_symbolEn": "Hand",
      "party_symbolMr": "हात"
    },
    {
      "key": "bjp",
      "shortNameEn": "BJP",
      "shortNameMr": "भाजप",
      "nameEn": "Bharatiya Janata Party",
      "nameMr": "भारतीय जनता पार्टी",
      "image": "bjp.png",
      "party_symbolEn": "Lotus",
      "party_symbolMr": "कमळ"
    },
    {
      "key": "ncp_ajit",
      "shortNameEn": "NCP (Ajit)",
      "shortNameMr": "राष्ट्रवादी (अजित पवार)",
      "nameEn": "Nationalist Congress Party (Ajit Pawar)",
      "nameMr": "राष्ट्रवादी काँग्रेस पक्ष (अजित पवार)",
      "image": "ncp_ajit.png",
      "party_symbolEn": "Clock",
      "party_symbolMr": "घड्याळ"
    },
    {
      "key": "ncp_sp",
      "shortNameEn": "NCP (Sharad)",
      "shortNameMr": "राष्ट्रवादी (शरद पवार)",
      "nameEn": "Nationalist Congress Party (Sharad Pawar)",
      "nameMr": "राष्ट्रवादी काँग्रेस पक्ष (शरद पवार)",
      "image": "ncp_sp.png",
      "party_symbolEn": "A Traditional Trumpet",
      "party_symbolMr": "तुतारी"
    },
    {
      "key": "shiv_sena_shinde",
      "shortNameEn": "Shiv Sena (Shinde)",
      "shortNameMr": "शिवसेना (शिंदे)",
      "nameEn": "Balasahebanchi Shiv Sena (Shinde)",
      "nameMr": "बाळासाहेबांची शिवसेना (शिंदे)",
      "image": "shiv_sena_shinde.png",
      "party_symbolEn": "Bow - Arrow",
      "party_symbolMr": "धनुष्यबाण"
    },
    {
      "key": "shiv_sena_ubt",
      "shortNameEn": "Shiv Sena (UBT)",
      "shortNameMr": "शिवसेना (उद्धव)",
      "nameEn": "Shiv Sena (Uddhav Balasaheb Thackeray)",
      "nameMr": "शिवसेना (उद्धव बाळासाहेब ठाकरे)",
      "image": "shiv_sena_ubt.jpeg",
      "party_symbolEn": "Torch",
      "party_symbolMr": "मशाल"
    },
    {
      "key": "mns",
      "shortNameEn": "MNS",
      "shortNameMr": "मनसे",
      "nameEn": "Maharashtra Navnirman Sena",
      "nameMr": "महाराष्ट्र नवनिर्माण सेना",
      "image": "mns.png",
      "party_symbolEn": "Railway Engine",
      "party_symbolMr": "रेल्वे इंजिन"
    },
    {
      "key": "cpi",
      "shortNameEn": "CPI",
      "shortNameMr": "भाकप",
      "nameEn": "Communist Party of India",
      "nameMr": "भारतीय कम्युनिस्ट पार्टी",
      "image": "cpi.png",
      "party_symbolEn": "Sickle and Hammer",
      "party_symbolMr": "हातोडा आणि हसूया"
    },
    {
      "key": "cpi_m",
      "shortNameEn": "CPI(M)",
      "shortNameMr": "भाकप(मा)",
      "nameEn": "Communist Party of India (Marxist)",
      "nameMr": "भारतीय कम्युनिस्ट पार्टी (मार्क्सवादी)",
      "image": "cpi_m.png",
      "party_symbolEn": "Hammer Sickle and Star",
      "party_symbolMr": "हातोडा हसूया आणि तारा"
    },
    {
      "key": "bsp",
      "shortNameEn": "BSP",
      "shortNameMr": "बसपा",
      "nameEn": "Bahujan Samaj Party",
      "nameMr": "बहुजन समाज पार्टी",
      "image": "bsp.png",
      "party_symbolEn": "Elephant",
      "party_symbolMr": "हत्ती"
    },
    {
      "key": "sp",
      "shortNameEn": "SP",
      "shortNameMr": "सपा",
      "nameEn": "Samajwadi Party",
      "nameMr": "समाजवादी पार्टी",
      "image": "sp.png",
      "party_symbolEn": "Bicycle",
      "party_symbolMr": "सायकल"
    },
    {
      "key": "aimim",
      "shortNameEn": "AIMIM",
      "shortNameMr": "एमआयएम",
      "nameEn": "All India Majlis-e-Ittehad-ul-Muslimeen",
      "nameMr": "ऑल इंडिया मजलिस-ए-इत्तेहादुल मुस्लिमीन",
      "image": "aimim.png",
      "party_symbolEn": "Kite",
      "party_symbolMr": "पतंग"
    },
    {
      "key": "npp",
      "shortNameEn": "NPP",
      "shortNameMr": "रापापा",
      "nameEn": "National People Party",
      "nameMr": "राष्ट्रीय लोक पार्टी",
      "image": "npp.png",
      "party_symbolEn": "Book",
      "party_symbolMr": "पुस्तक"
    },
    {
      "key": "pwpi",
      "shortNameEn": "PWPI",
      "shortNameMr": "कृपेका",
      "nameEn": "Peasants and Workers Party of India",
      "nameMr": "पीपल्स वर्कर्स पार्टी ऑफ इंडिया",
      "image": "Pwpisymbol.jpg",
      "party_symbolEn": "Farmer with Sickle",
      "party_symbolMr": "शेतकरी हसूया सह"
    },
    {
      "key": "vba",
      "shortNameEn": "VBA",
      "shortNameMr": "वंचित आघाडी",
      "nameEn": "Vanchit Bahujan Aghadi",
      "nameMr": "वंचित बहुजन आघाडी",
      "image": "vba.png",
      "party_symbolEn": "Unknown",
      "party_symbolMr": "अज्ञात"
    },
    {
      "key": "rsp",
      "shortNameEn": "RSP",
      "shortNameMr": "रासप",
      "nameEn": "Rashtriya Samaj Paksha",
      "nameMr": "राष्ट्रीय समाज पक्ष",
      "image": "rsp.jpg",
      "party_symbolEn": "Unknown",
      "party_symbolMr": "अज्ञात"
    },
    {
      "key": "bva",
      "shortNameEn": "BVA",
      "shortNameMr": "बाविआ",
      "nameEn": "Bahujan Vikas Aaghadi",
      "nameMr": "बहुजन विकास आघाडी",
      "image": "pwp.jpg",
      "party_symbolEn": "Whistle",
      "party_symbolMr": "शिट्टी"
    },
    {
      "key": "abs",
      "shortNameEn": "ABS",
      "shortNameMr": "अखिबासे",
      "nameEn": "Akhil Bharatiya Sena",
      "nameMr": "अखिल भारतीय सेना",
      "image": "default.png",
      "party_symbolEn": "Unknown",
      "party_symbolMr": "अज्ञात"
    },
    {
      "key": "independent",
      "shortNameEn": "IND",
      "shortNameMr": "अपक्ष",
      "nameEn": "Independent",
      "nameMr": "अपक्ष",
      "image": "independent.png",
      "party_symbolEn": "No Symbol",
      "party_symbolMr": "कोणतेही नाही"
    }
  ];

  /// Find party by key
  static Map<String, String>? getPartyByKey(String key) {
    try {
      return parties.firstWhere(
        (party) => party['key'] == key,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      debugPrint('Error finding party by key $key: $e');
      return null;
    }
  }

  /// Find party by name (English or Marathi)
  static Map<String, String>? getPartyByName(String name) {
    try {
      return parties.firstWhere(
        (party) =>
            party['nameEn']?.toLowerCase() == name.toLowerCase() ||
            party['nameMr'] == name ||
            party['shortNameEn']?.toLowerCase() == name.toLowerCase() ||
            party['shortNameMr'] == name,
        orElse: () => <String, String>{},
      );
    } catch (e) {
      debugPrint('Error finding party by name $name: $e');
      return null;
    }
  }

  /// Get party key from name
  static String? getPartyKeyFromName(String name) {
    final party = getPartyByName(name);
    return party?['key'];
  }

  /// Get party display name (automatically detects locale) - SHORT NAMES
  static String getPartyDisplayName(String key) {
    final party = getPartyByKey(key);
    if (party == null) return key;

    // Default to English short name, fallback to full name
    return party['shortNameEn'] ?? party['nameEn'] ?? key;
  }

  /// Get party display name with explicit locale preference - SHORT NAMES
  static String getPartyDisplayNameWithLocale(String key, String locale) {
    final party = getPartyByKey(key);
    if (party == null) return key;

    if (locale == 'mr' && party['shortNameMr'] != null) {
      return party['shortNameMr']!;
    }

    return party['shortNameEn'] ?? party['nameEn'] ?? key;
  }

  /// Get party full name (automatically detects locale) - FULL NAMES
  static String getPartyFullName(String key) {
    final party = getPartyByKey(key);
    if (party == null) return key;

    // Default to English full name, fallback to short name
    return party['nameEn'] ?? party['shortNameEn'] ?? key;
  }

  /// Get party full name with explicit locale preference - FULL NAMES
  static String getPartyFullNameWithLocale(String key, String locale) {
    final party = getPartyByKey(key);
    if (party == null) return key;

    if (locale == 'mr' && party['nameMr'] != null) {
      return party['nameMr']!;
    }

    return party['nameEn'] ?? party['shortNameEn'] ?? key;
  }

  /// Get party symbol name with explicit locale preference
  static String getPartySymbolNameWithLocale(String key, String locale) {
    final party = getPartyByKey(key);
    if (party == null) return 'Unknown';

    if (locale == 'mr' && party['party_symbolMr'] != null) {
      return party['party_symbolMr']!;
    }

    return party['party_symbolEn'] ?? 'Unknown';
  }

  /// Convert old party name format to new key format
  /// This helps with data migration from old system to new key-based system
  static String? convertOldPartyNameToKey(String oldPartyName) {
    // Try to find the party by name first
    final party = getPartyByName(oldPartyName);
    if (party != null && party.isNotEmpty) {
      return party['key'];
    }

    // Handle special cases for common variations
    final normalizedName = oldPartyName.toLowerCase().trim();

    if (normalizedName.contains('congress') || normalizedName.contains('कॉंग्रेस')) {
      return 'inc';
    } else if (normalizedName.contains('bjp') || normalizedName.contains('भाजप')) {
      return 'bjp';
    } else if (normalizedName.contains('ncp') || normalizedName.contains('राष्ट्रवादी')) {
      // Default to Ajit Pawar faction for NCP
      return 'ncp_ajit';
    } else if (normalizedName.contains('shiv sena') || normalizedName.contains('शिवसेना')) {
      // Default to Shinde faction for Shiv Sena
      return 'shiv_sena_shinde';
    } else if (normalizedName.contains('independent') || normalizedName.contains('अपक्ष')) {
      return 'independent';
    }

    return null;
  }

  /// Get all party keys for reference
  static List<String> getAllPartyKeys() {
    return parties.map((party) => party['key']!).toList();
  }

  /// Get all party names (English) for reference
  static List<String> getAllPartyNames() {
    return parties.map((party) => party['nameEn']!).toList();
  }

  /// Get all party short names (English) for reference
  static List<String> getAllPartyShortNames() {
    return parties.map((party) => party['shortNameEn']!).toList();
  }

  /// Get party symbol path with support for independent candidate symbol images
  /// Optimized: Only caches for independent candidates, direct lookup for parties
  static String getPartySymbolPath(String party, {Candidate? candidate}) {
    debugPrint('🔍 [SymbolUtils] Getting symbol for party: $party');

    // Handle independent candidates with potential caching
    if (party.toLowerCase().contains('independent') || party.trim().isEmpty) {
      debugPrint('🎯 [SymbolUtils] Independent candidate detected');

      // Only cache if we have candidate data
      if (candidate != null) {
        final cacheKey = 'independent_${candidate.candidateId}';

        // Check cache first
        if (_symbolCache.containsKey(cacheKey)) {
          return _symbolCache[cacheKey]!;
        }

        // Check for symbolUrl in candidate data (primary source)
        if (candidate.symbolUrl != null &&
            candidate.symbolUrl!.isNotEmpty &&
            candidate.symbolUrl!.startsWith('http')) {
          debugPrint('🎨 [SymbolUtils] Using candidate.symbolUrl: ${candidate.symbolUrl}');
          _symbolCache[cacheKey] = candidate.symbolUrl!;
          return candidate.symbolUrl!;
        }

        // Fallback: Check for uploaded symbol image URL in media
        if (candidate.extraInfo?.media != null &&
            candidate.extraInfo!.media!.isNotEmpty) {
          final symbolImageItem = candidate.extraInfo!.media!.firstWhere(
            (item) => item['type'] == 'symbolImage',
            orElse: () => <String, dynamic>{},
          );
          if (symbolImageItem.isNotEmpty) {
            final symbolImageUrl = symbolImageItem['url'] as String?;
            if (symbolImageUrl != null &&
                symbolImageUrl.isNotEmpty &&
                symbolImageUrl.startsWith('http')) {
              debugPrint('🎨 [SymbolUtils] Using uploaded image URL from media: $symbolImageUrl');
              _symbolCache[cacheKey] = symbolImageUrl;
              return symbolImageUrl;
            }
          }
        }
      }

      // Fallback for independent candidates (no caching needed for static asset)
      debugPrint('🎨 [SymbolUtils] Using default independent asset');
      return 'assets/symbols/independent.png';
    }

    // For regular parties - Direct lookup, no caching needed
    debugPrint('🏛️ [SymbolUtils] Party-affiliated candidate detected');

    // First check if the party string is already a key
    Map<String, String>? partyData = getPartyByKey(party);

    // If not a key, try to find party by name
    if (partyData == null || partyData.isEmpty) {
      partyData = getPartyByName(party);

      // If not found by name, try to get key from name and then find by key
      if (partyData == null || partyData.isEmpty) {
        String? partyKey = getPartyKeyFromName(party);
        if (partyKey != null) {
          partyData = getPartyByKey(partyKey);
        }
      }
    }

    // Handle special cases for common variations
    if (partyData == null || partyData.isEmpty) {
      if (party.contains('Congress') || party.contains('कॉंग्रेस')) {
        partyData = getPartyByKey('inc');
      } else if (party.contains('BJP') || party.contains('भाजप')) {
        partyData = getPartyByKey('bjp');
      } else if (party.contains('NCP') || party.contains('राष्ट्रवादी')) {
        partyData = getPartyByKey('ncp_ajit'); // Default to Ajit faction
      } else if (party.contains('Shiv Sena') || party.contains('शिवसेना')) {
        partyData = getPartyByKey('shiv_sena_shinde'); // Default to Shinde faction
      }
    }

    // Return symbol path from party data
    if (partyData != null && partyData['image'] != null) {
      final result = 'assets/symbols/${partyData['image']!}';
      debugPrint('🏛️ [SymbolUtils] Using party asset: $result');
      return result;
    }

    debugPrint('🏛️ [SymbolUtils] Using default asset');
    return 'assets/symbols/default.png';
  }

  /// Get party symbol path using Party model (preferred method)
  /// This method uses the symbolPath from the Party model when available
  static String getPartySymbolPathFromParty(
    Party party, {
    Candidate? candidate,
  }) {
    // Create cache key
    final cacheKey = 'party_${party.id}_${candidate?.candidateId ?? 'null'}';

    // Return cached result if available
    if (_symbolCache.containsKey(cacheKey)) {
      return _symbolCache[cacheKey]!;
    }

    debugPrint(
      '🔍 [SymbolUtils] For party: ${party.name}, Candidate: ${candidate?.name ?? 'null'}',
    );

    // First check if candidate data exists for independent candidates
    if (candidate != null &&
        (party.id == 'independent' ||
            party.name.toLowerCase().contains('independent'))) {
      debugPrint('🎯 [SymbolUtils] Independent candidate detected');

      // Check for symbolUrl in candidate data (primary source)
      if (candidate.symbolUrl != null &&
          candidate.symbolUrl!.isNotEmpty &&
          candidate.symbolUrl!.startsWith('http')) {
        debugPrint('🎨 [SymbolUtils] Using candidate.symbolUrl: ${candidate.symbolUrl}');
        _symbolCache[cacheKey] = candidate.symbolUrl!;
        return candidate.symbolUrl!;
      }

      // Fallback: Check for uploaded symbol image URL in media
      if (candidate.extraInfo?.media != null &&
          candidate.extraInfo!.media!.isNotEmpty) {
        final symbolImageItem = candidate.extraInfo!.media!.firstWhere(
          (item) => item['type'] == 'symbolImage',
          orElse: () => <String, dynamic>{},
        );
        if (symbolImageItem.isNotEmpty) {
          final symbolImageUrl = symbolImageItem['url'] as String?;
          if (symbolImageUrl != null &&
              symbolImageUrl.isNotEmpty &&
              symbolImageUrl.startsWith('http')) {
            debugPrint(
              '🎨 [SymbolUtils] Using uploaded image URL from media: $symbolImageUrl',
            );
            _symbolCache[cacheKey] = symbolImageUrl;
            return symbolImageUrl; // Return the Firebase Storage URL
          }
        }
      }

      // Fallback to independent symbol
      const result = 'assets/symbols/independent.png';
      _symbolCache[cacheKey] = result;
      return result;
    }

    // Use symbolPath from Party model if available
    if (party.symbolPath != null && party.symbolPath!.isNotEmpty) {
      debugPrint(
        '🏛️ [SymbolUtils] Using party model symbolPath: ${party.symbolPath}',
      );
      _symbolCache[cacheKey] = party.symbolPath!;
      return party.symbolPath!;
    }

    // Fallback to the existing mapping logic
    debugPrint(
      '🏛️ [SymbolUtils] Falling back to legacy mapping for party: ${party.name}',
    );
    return getPartySymbolPath(party.name, candidate: candidate);
  }

  /// Get the appropriate ImageProvider for a symbol path
  /// This eliminates the need for redundant ternary expressions
  static ImageProvider getSymbolImageProvider(String symbolPath) {
    if (symbolPath.startsWith('http')) {
      return NetworkImage(symbolPath);
    } else {
      return AssetImage(symbolPath);
    }
  }

  /// Clear the symbol cache (useful when candidate data changes)
  static void clearCache() {
    _symbolCache.clear();
    debugPrint('🧹 [SymbolUtils] Symbol cache cleared');
  }

  /// Get cache size for debugging
  static int getCacheSize() {
    return _symbolCache.length;
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _symbolCache.length,
      'cachedKeys': _symbolCache.keys.toList(),
    };
  }
}
