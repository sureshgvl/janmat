import '../models/candidate_model.dart';
import '../../../utils/app_logger.dart';

/// Service responsible for candidate search and filtering logic.
/// Handles local search operations and debouncing.
class CandidateSearchService {
  /// Perform local search on candidates by name or party
  List<Candidate> searchCandidates(List<Candidate> candidates, String query) {
    if (query.isEmpty) {
      return candidates;
    }

    final lowercaseQuery = query.toLowerCase();

    final filteredCandidates = candidates.where((candidate) {
      // Search in candidate name
      final nameMatch = candidate.basicInfo?.fullName
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      // Search in party name
      final partyMatch = candidate.party
          .toLowerCase()
          .contains(lowercaseQuery);

      // Search in district name (if available)
      final districtMatch = candidate.location.districtId
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      // Search in body name (if available)
      final bodyMatch = candidate.location.bodyId
          ?.toLowerCase()
          .contains(lowercaseQuery) ?? false;

      return nameMatch || partyMatch || districtMatch || bodyMatch;
    }).toList();

    AppLogger.candidate('🔍 Search completed: "${query}" -> ${filteredCandidates.length} results');

    return filteredCandidates;
  }

  /// Filter candidates by location (district, body, ward)
  List<Candidate> filterByLocation(
    List<Candidate> candidates,
    String? districtId,
    String? bodyId,
    String? wardId,
  ) {
    return candidates.where((candidate) {
      final districtMatch = districtId == null ||
          candidate.location.districtId == districtId;

      final bodyMatch = bodyId == null ||
          candidate.location.bodyId == bodyId;

      final wardMatch = wardId == null ||
          candidate.location.wardId == wardId;

      return districtMatch && bodyMatch && wardMatch;
    }).toList();
  }

  /// Sort candidates by different criteria
  List<Candidate> sortCandidates(List<Candidate> candidates, SortOption sortBy) {
    final sortedCandidates = List<Candidate>.from(candidates);

    switch (sortBy) {
      case SortOption.name:
        sortedCandidates.sort((a, b) =>
            (a.basicInfo?.fullName ?? '').compareTo(b.basicInfo?.fullName ?? ''));
        break;

      case SortOption.party:
        sortedCandidates.sort((a, b) => a.party.compareTo(b.party));
        break;

      case SortOption.followers:
        sortedCandidates.sort((a, b) => (b.followersCount).compareTo(a.followersCount));
        break;

      case SortOption.recent:
        sortedCandidates.sort((a, b) =>
            (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;

      case SortOption.none:
      default:
        // No sorting
        break;
    }

    return sortedCandidates;
  }

  /// Get search suggestions based on current candidates
  List<String> getSearchSuggestions(List<Candidate> candidates, String query) {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    final suggestions = <String>{};

    for (final candidate in candidates) {
      // Add name suggestions
      final name = candidate.basicInfo?.fullName;
      if (name != null && name.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(name);
      }

      // Add party suggestions
      final party = candidate.party;
      if (party.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(party);
      }
    }

    // Limit to top 5 suggestions and sort alphabetically
    return suggestions.take(5).toList()..sort();
  }

  /// Check if search query matches candidate
  bool matchesSearch(Candidate candidate, String query) {
    if (query.isEmpty) return true;

    final lowercaseQuery = query.toLowerCase();

    final nameMatch = candidate.basicInfo?.fullName
        ?.toLowerCase()
        .contains(lowercaseQuery) ?? false;

    final partyMatch = candidate.party
        .toLowerCase()
        .contains(lowercaseQuery);

    return nameMatch || partyMatch;
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStats(List<Candidate> original, List<Candidate> filtered, String query) {
    return {
      'total_candidates': original.length,
      'filtered_count': filtered.length,
      'search_query': query,
      'has_results': filtered.isNotEmpty,
      'search_time_ms': DateTime.now().millisecondsSinceEpoch, // Placeholder for timing
    };
  }
}

/// Enum for sorting options
enum SortOption {
  none,
  name,
  party,
  followers,
  recent,
}

/// Extension to get display name for sort options
extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.name:
        return 'Name';
      case SortOption.party:
        return 'Party';
      case SortOption.followers:
        return 'Followers';
      case SortOption.recent:
        return 'Recent';
      case SortOption.none:
      default:
        return 'Default';
    }
  }
}
