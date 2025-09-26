import 'package:flutter/material.dart';
import 'maharashtra_utils.dart';

/// Utility class for mapping user locations to election-specific information
/// Helps users understand where they need to participate in elections
class ElectionLocationMapper {
  /// Map district, body, and ward to election type
  static String getElectionTypeForLocation({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    // Get body information
    final body = _getBodyById(bodyId);
    if (body == null) return 'unknown';

    // Map body types to election types
    final bodyType = body['type']?.toString().toLowerCase() ?? '';
    switch (bodyType) {
      case 'municipal corporation':
      case 'mahanagar palika':
      case 'महानगरपालिका':
        return 'municipal_corporation';

      case 'municipal council':
      case 'nagar parishad':
      case 'नगरपरिषद':
        return 'municipal_council';

      case 'nagar panchayat':
      case 'नगर पंचायत':
        return 'nagar_panchayat';

      case 'zilla parishad':
      case 'जिल्हा परिषद':
        return 'zilla_parishad';

      case 'panchayat samiti':
      case 'पंचायत समिती':
        return 'panchayat_samiti';

      case 'gram panchayat':
      case 'ग्राम पंचायत':
        return 'gram_panchayat';

      default:
        return 'unknown';
    }
  }

  /// Get polling station information based on location
  static Map<String, String> getPollingStationInfo({
    required String districtId,
    required String bodyId,
    required String wardId,
    String? area,
  }) {
    final electionType = getElectionTypeForLocation(
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    // Get body information
    final body = _getBodyById(bodyId);
    if (body == null) {
      return {
        'pollingStation': 'Unknown',
        'constituency': 'Unknown',
        'electionType': electionType,
      };
    }

    // Generate polling station based on ward and area
    final wardNumber = _extractWardNumber(wardId);
    final bodyName = body['name']?.toString() ?? 'Unknown';
    final pollingStation = _generatePollingStationName(
      bodyName,
      wardNumber,
      area,
    );

    return {
      'pollingStation': pollingStation,
      'constituency': '$bodyName - Ward $wardNumber',
      'electionType': electionType,
    };
  }

  /// Get election information for a user based on their location
  static Map<String, dynamic> getElectionInfoForUser({
    required String districtId,
    required String bodyId,
    required String wardId,
    String? area,
  }) {
    final pollingInfo = getPollingStationInfo(
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
      area: area,
    );

    final body = _getBodyById(bodyId);
    final district = MaharashtraUtils.getDistrictByKey(districtId);

    return {
      'electionType': pollingInfo['electionType'],
      'pollingStation': pollingInfo['pollingStation'],
      'constituency': pollingInfo['constituency'],
      'bodyName': body?['name']?.toString() ?? 'Unknown',
      'bodyType': body?['type']?.toString() ?? 'Unknown',
      'districtName': district?['nameEn'] ?? 'Unknown',
      'districtNameMr': district?['nameMr'] ?? 'Unknown',
      'wardNumber': _extractWardNumber(wardId),
      'area': area,
      'state': 'Maharashtra', // Add state information
      'stateCode': 'MH', // Add state code
    };
  }

  /// Get upcoming elections for a specific location
  static List<Map<String, String>> getUpcomingElectionsForLocation({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    final electionType = getElectionTypeForLocation(
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    // This would typically come from an API or database
    // For now, returning mock data based on election types
    final mockElections = <Map<String, String>>[];

    switch (electionType) {
      case 'municipal_corporation':
        mockElections.add({
          'name': 'Municipal Corporation Elections 2025',
          'nameMr': 'महानगरपालिका निवडणुका 2025',
          'date': 'Expected: March 2025',
          'status': 'upcoming',
        });
        break;

      case 'municipal_council':
        mockElections.add({
          'name': 'Municipal Council Elections 2025',
          'nameMr': 'नगरपरिषद निवडणुका 2025',
          'date': 'Expected: April 2025',
          'status': 'upcoming',
        });
        break;

      case 'zilla_parishad':
        mockElections.add({
          'name': 'Zilla Parishad Elections 2025',
          'nameMr': 'जिल्हा परिषद निवडणुका 2025',
          'date': 'Expected: February 2025',
          'status': 'upcoming',
        });
        break;

      case 'panchayat_samiti':
        mockElections.add({
          'name': 'Panchayat Samiti Elections 2025',
          'nameMr': 'पंचायत समिती निवडणुका 2025',
          'date': 'Expected: May 2025',
          'status': 'upcoming',
        });
        break;
    }

    return mockElections;
  }

  /// Get election-specific guidance for users
  static String getElectionGuidance({
    required String electionType,
    required String districtId,
  }) {
    switch (electionType) {
      case 'municipal_corporation':
        return 'For Municipal Corporation elections, you will vote at your designated polling station in your ward. Make sure to carry your voter ID card.';

      case 'municipal_council':
        return 'Municipal Council elections are conducted for your local town/city administration. Check your voter slip for exact polling station details.';

      case 'nagar_panchayat':
        return 'Nagar Panchayat elections are for small towns. Your polling station will be within your local area.';

      case 'zilla_parishad':
        return 'Zilla Parishad elections are for district-level rural governance. Polling stations are usually in local schools or community halls.';

      case 'panchayat_samiti':
        return 'Panchayat Samiti elections are for block-level administration. Vote at your designated polling station in the taluka.';

      case 'gram_panchayat':
        return 'Gram Panchayat elections are for village-level administration. Polling usually happens at the village community center.';

      default:
        return 'Please verify your election details with your local election office.';
    }
  }

  /// Get election-specific guidance in Marathi
  static String getElectionGuidanceMr({
    required String electionType,
    required String districtId,
  }) {
    switch (electionType) {
      case 'municipal_corporation':
        return 'महानगरपालिका निवडणुकीसाठी आपण आपल्या वॉर्डमधील नियुक्त मतदान केंद्रावर मतदान कराल. आपला मतदार ओळखपत्र अवश्य बाळगा.';

      case 'municipal_council':
        return 'नगरपरिषद निवडणुका आपल्या स्थानिक शहर/नगरच्या प्रशासनासाठी घेतल्या जातात. मतदान केंद्राचे तपशील जाणून घेण्यासाठी आपली मतदार पावती तपासा.';

      case 'nagar_panchayat':
        return 'नगर पंचायत निवडणुका लहान शहरांसाठी असतात. आपले मतदान केंद्र आपल्या स्थानिक परिसरात असेल.';

      case 'zilla_parishad':
        return 'जिल्हा परिषद निवडणुका जिल्हा-स्तरीय ग्रामीण शासनासाठी असतात. मतदान केंद्रे सहसा स्थानिक शाळा किंवा सामुदायिक सभागृहात असतात.';

      case 'panchayat_samiti':
        return 'पंचायत समिती निवडणुका तालुका-स्तरीय प्रशासनासाठी असतात. तालुक्यातील आपल्या नियुक्त मतदान केंद्रावर मतदान करा.';

      case 'gram_panchayat':
        return 'ग्राम पंचायत निवडणुका गाव-स्तरीय प्रशासनासाठी असतात. मतदान सहसा गावच्या सामुदायिक केंद्रात होते.';

      default:
        return 'कृपया आपल्या स्थानिक निवडणूक कार्यालयात आपले निवडणूक तपशील सत्यापित करा.';
    }
  }

  /// Check if elections are currently happening in a location
  static bool areElectionsHappening({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    // This would typically check against a real-time election schedule
    // For now, returning false as default
    return false;
  }

  /// Get election status for a location
  static String getElectionStatus({
    required String districtId,
    required String bodyId,
    required String wardId,
  }) {
    final upcomingElections = getUpcomingElectionsForLocation(
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    );

    if (upcomingElections.isNotEmpty) {
      return 'upcoming';
    }

    if (areElectionsHappening(
      districtId: districtId,
      bodyId: bodyId,
      wardId: wardId,
    )) {
      return 'ongoing';
    }

    return 'none';
  }

  // Helper methods
  static Map<String, dynamic>? _getBodyById(String bodyId) {
    // This would typically fetch from a database
    // For now, returning null as we don't have actual body data
    return null;
  }

  static int _extractWardNumber(String wardId) {
    final match = RegExp(r'ward_(\d+)').firstMatch(wardId.toLowerCase());
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  static String _generatePollingStationName(
    String bodyName,
    int wardNumber,
    String? area,
  ) {
    if (area != null && area.isNotEmpty) {
      return '$bodyName - Ward $wardNumber ($area)';
    }
    return '$bodyName - Ward $wardNumber';
  }

  /// Get all election types available in Maharashtra
  static List<Map<String, String>> getAllElectionTypes() {
    return [
      {
        'key': 'municipal_corporation',
        'nameEn': 'Municipal Corporation',
        'nameMr': 'महानगरपालिका',
      },
      {
        'key': 'municipal_council',
        'nameEn': 'Municipal Council',
        'nameMr': 'नगरपरिषद',
      },
      {
        'key': 'nagar_panchayat',
        'nameEn': 'Nagar Panchayat',
        'nameMr': 'नगर पंचायत',
      },
      {
        'key': 'zilla_parishad',
        'nameEn': 'Zilla Parishad',
        'nameMr': 'जिल्हा परिषद',
      },
      {
        'key': 'panchayat_samiti',
        'nameEn': 'Panchayat Samiti',
        'nameMr': 'पंचायत समिती',
      },
      {
        'key': 'gram_panchayat',
        'nameEn': 'Gram Panchayat',
        'nameMr': 'ग्राम पंचायत',
      },
    ];
  }

}