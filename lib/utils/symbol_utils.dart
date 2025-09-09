import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/candidate_model.dart';

/// Centralized utility for party symbol path resolution
/// Optimized to avoid redundant function calls and computations
class SymbolUtils {
  // Cache for symbol paths to avoid repeated computations
  static final Map<String, String> _symbolCache = {};

  /// Get party symbol path with support for independent candidate symbol images
  /// This is the centralized, optimized version that replaces all duplicate functions
  static String getPartySymbolPath(String party, {Candidate? candidate}) {
    // Create cache key
    final cacheKey = '${party}_${candidate?.candidateId ?? 'null'}';

    // Return cached result if available
    if (_symbolCache.containsKey(cacheKey)) {
      return _symbolCache[cacheKey]!;
    }

    // First check if candidate data exists
    if (candidate == null) {
      debugPrint('⚠️ [SymbolUtils] No candidate data available');
      const result = 'assets/symbols/default.png';
      _symbolCache[cacheKey] = result;
      return result;
    }

    debugPrint('🔍 [SymbolUtils] For party: $party, Candidate: ${candidate.name}');

    // Handle independent candidates - check for symbol image URL first
    if (party.toLowerCase().contains('independent') || party.trim().isEmpty) {
      debugPrint('🎯 [SymbolUtils] Independent candidate detected');

      // For independent candidates, check if there's a symbol image URL in extraInfo
      if (candidate.extraInfo?.media != null) {
        final symbolImageUrl = candidate.extraInfo!.media!['symbolImageUrl'];
        if (symbolImageUrl != null && symbolImageUrl.isNotEmpty && symbolImageUrl.startsWith('http')) {
          debugPrint('🎨 [SymbolUtils] Using uploaded image URL: $symbolImageUrl');
          _symbolCache[cacheKey] = symbolImageUrl;
          return symbolImageUrl; // Return the Firebase Storage URL
        }
      }

      // Fallback to default independent symbol if no valid image URL
      debugPrint('🎨 [SymbolUtils] Using default independent asset');
      const result = 'assets/symbols/independent.png';
      _symbolCache[cacheKey] = result;
      return result;
    }

    // For party-affiliated candidates, use the existing party symbol mapping
    debugPrint('🏛️ [SymbolUtils] Party-affiliated candidate detected');
    final partyMapping = {
      'Indian National Congress': 'inc.png',
      'Bharatiya Janata Party': 'bjp.png',
      'Nationalist Congress Party (Ajit Pawar faction)': 'ncp_ajit.png',
      'Nationalist Congress Party – Sharadchandra Pawar': 'ncp_sp.png',
      'Shiv Sena (Eknath Shinde faction)': 'shiv_sena_shinde.png',
      'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)': 'shiv_sena_ubt.jpeg',
      'Maharashtra Navnirman Sena': 'mns.png',
      'Communist Party of India': 'cpi.png',
      'Communist Party of India (Marxist)': 'cpi_m.png',
      'Bahujan Samaj Party': 'bsp.png',
      'Samajwadi Party': 'sp.png',
      'All India Majlis-e-Ittehad-ul-Muslimeen': 'aimim.png',
      'National Peoples Party': 'npp.png',
      'Peasants and Workers Party of India': 'pwp.jpg',
      'Vanchit Bahujan Aaghadi': 'vba.png',
      'Rashtriya Samaj Paksha': 'default.png',
    };

    // First try exact match
    if (partyMapping.containsKey(party)) {
      final symbolFile = partyMapping[party]!;
      final result = 'assets/symbols/$symbolFile';
      debugPrint('🏛️ [SymbolUtils] Using party asset: $result');
      _symbolCache[cacheKey] = result;
      return result;
    }

    // Try case-insensitive match
    final upperParty = party.toUpperCase();
    for (var entry in partyMapping.entries) {
      if (entry.key.toUpperCase() == upperParty) {
        final result = 'assets/symbols/${entry.value}';
        debugPrint('🏛️ [SymbolUtils] Using party asset (case-insensitive): $result');
        _symbolCache[cacheKey] = result;
        return result;
      }
    }

    // Try partial matches for common variations
    final partialMatches = {
      'INDIAN NATIONAL CONGRESS': 'inc.png',
      'INDIA NATIONAL CONGRESS': 'inc.png',
      'BHARATIYA JANATA PARTY': 'bjp.png',
      'NATIONALIST CONGRESS PARTY': 'ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY AJIT': 'ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY SP': 'ncp_sp.png',
      'SHIV SENA': 'shiv_sena_ubt.jpeg',
      'SHIV SENA UBT': 'shiv_sena_ubt.jpeg',
      'SHIV SENA SHINDE': 'shiv_sena_shinde.png',
      'MAHARASHTRA NAVNIRMAN SENA': 'mns.png',
      'COMMUNIST PARTY OF INDIA': 'cpi.png',
      'COMMUNIST PARTY OF INDIA MARXIST': 'cpi_m.png',
      'BAHUJAN SAMAJ PARTY': 'bsp.png',
      'SAMAJWADI PARTY': 'sp.png',
      'ALL INDIA MAJLIS E ITTEHADUL MUSLIMEEN': 'aimim.png',
      'ALL INDIA MAJLIS-E-ITTEHADUL MUSLIMEEN': 'aimim.png',
      'NATIONAL PEOPLES PARTY': 'npp.png',
      'PEASANT AND WORKERS PARTY': 'pwp.jpg',
      'VANCHIT BAHUJAN AGHADI': 'vba.png',
      'REVOLUTIONARY SOCIALIST PARTY': 'default.png',
    };

    for (var entry in partialMatches.entries) {
      if (upperParty.contains(entry.key.toUpperCase().replaceAll(' ', '')) ||
          entry.key.toUpperCase().contains(upperParty.replaceAll(' ', ''))) {
        final result = 'assets/symbols/${entry.value}';
        debugPrint('🏛️ [SymbolUtils] Using party asset (partial match): $result');
        _symbolCache[cacheKey] = result;
        return result;
      }
    }

    debugPrint('🏛️ [SymbolUtils] Using default asset');
    const result = 'assets/symbols/default.png';
    _symbolCache[cacheKey] = result;
    return result;
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