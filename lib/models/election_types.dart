// Election type constants and enums for the Janmat app

// Main election types for voters
enum VoterElectionType {
  municipalCorporation,
  municipalCouncil,
  nagarPanchayat,
  zpPsCombined, // Zilla Parishad + Panchayat Samiti combined
}

// Election type string constants
class ElectionTypeConstants {
  // Voter election types
  static const String municipalCorporation = 'municipal_corporation';
  static const String municipalCouncil = 'municipal_council';
  static const String nagarPanchayat = 'nagar_panchayat';
  static const String zpPsCombined = 'zp_ps_combined';

  // Sub-election types for ZP+PS combined
  static const String zp = 'zp'; // Zilla Parishad
  static const String ps = 'ps'; // Panchayat Samiti

  // Body types that correspond to election types
  static const Map<String, String> electionTypeToBodyType = {
    municipalCorporation: 'municipal_corporation',
    municipalCouncil: 'municipal_council',
    nagarPanchayat: 'nagar_panchayat',
    zpPsCombined: 'zilla_parishad', // ZP part
  };

  // Get all available election types for voters
  static List<String> getAllVoterElectionTypes() {
    return [
      municipalCorporation,
      municipalCouncil,
      nagarPanchayat,
      zpPsCombined,
    ];
  }

  // Get election types available for a specific district
  static List<String> getElectionTypesForDistrict(String districtId) {
    // This would typically check district configuration
    // For now, return all types (can be customized per district)
    return getAllVoterElectionTypes();
  }

  // Get Marathi translations for election types
  static String getElectionTypeDisplayName(String electionType, {bool inMarathi = false}) {
    if (inMarathi) {
      switch (electionType) {
        case municipalCorporation:
          return 'महानगरपालिका';
        case municipalCouncil:
          return 'नगरपरिषद';
        case nagarPanchayat:
          return 'नगर पंचायत';
        case zpPsCombined:
          return 'जिल्हा परिषद + पंचायत समिती';
        default:
          return electionType;
      }
    } else {
      switch (electionType) {
        case municipalCorporation:
          return 'Municipal Corporation';
        case municipalCouncil:
          return 'Municipal Council';
        case nagarPanchayat:
          return 'Nagar Panchayat';
        case zpPsCombined:
          return 'ZP + PS Combined';
        default:
          return electionType;
      }
    }
  }

  // Check if election type requires multiple wards
  static bool requiresMultipleWards(String electionType) {
    return electionType == zpPsCombined;
  }

  // Get number of wards required for election type
  static int getRequiredWardCount(String electionType) {
    return requiresMultipleWards(electionType) ? 2 : 1;
  }
}

// Chat room type constants
class ChatRoomTypeConstants {
  static const String areaChat = 'area_chat';
  static const String zpChat = 'zp_chat';
  static const String psChat = 'ps_chat';

  // Generate room ID based on election type and area
  static String generateRoomId(String area, String electionType) {
    if (electionType == ElectionTypeConstants.zp) {
      return '${area}_zp_chat';
    } else if (electionType == ElectionTypeConstants.ps) {
      return '${area}_ps_chat';
    } else {
      return '${area}_chat';
    }
  }
}

