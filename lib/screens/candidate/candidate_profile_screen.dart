import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/candidate_model.dart';
import '../../controllers/candidate_controller.dart';
import '../../widgets/candidate/profile_header.dart';
import '../../widgets/candidate/info_tab.dart';
import '../../widgets/candidate/manifesto_tab.dart';
import '../../widgets/candidate/media_tab.dart';
import '../../widgets/candidate/contact_tab.dart';

class CandidateProfileScreen extends StatefulWidget {
  const CandidateProfileScreen({super.key});

  @override
  State<CandidateProfileScreen> createState() => _CandidateProfileScreenState();
}

class _CandidateProfileScreenState extends State<CandidateProfileScreen> {
  late Candidate candidate;
  final CandidateController controller = Get.find<CandidateController>();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    candidate = Get.arguments as Candidate;

    // Add dummy data for demonstration if data is missing
    _addDummyDataIfNeeded();

    // Check follow status when screen loads
    if (currentUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.checkFollowStatus(currentUserId!, candidate.candidateId);
      });
    }
  }

  void _addDummyDataIfNeeded() {
    // Create dummy extra info if not present
    if (candidate.extraInfo == null) {
      candidate = candidate.copyWith(
        extraInfo: ExtraInfo(
          bio: "I am a dedicated public servant with over 15 years of experience in community development and local governance. My commitment to transparency, accountability, and inclusive growth has been the cornerstone of my political career. I believe in empowering every citizen and creating opportunities for sustainable development in our ward.",
          achievements: [
            "Successfully implemented 5 new community health camps serving over 2000 residents",
            "Led the construction of 3 new public schools benefiting 1500+ students",
            "Introduced digital literacy programs for senior citizens across the ward",
            "Established clean water supply systems reaching 500+ households",
            "Organized vocational training programs for unemployed youth",
            "Implemented waste management initiatives reducing pollution by 40%"
          ],
          manifesto: "Building a prosperous future through inclusive development, sustainable infrastructure, and community empowerment.",
          manifestoPdf: "https://example.com/manifesto.pdf",
          contact: Contact(
            phone: candidate.contact.phone,
            email: candidate.contact.email ?? "candidate@example.com",
            socialLinks: {
              "Facebook": "https://facebook.com/candidate",
              "Twitter": "https://twitter.com/candidate",
              "Instagram": "https://instagram.com/candidate",
              "YouTube": "https://youtube.com/candidate",
              "Website": "https://candidate-website.com"
            }
          ),
          media: {
            "photos": ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"],
            "videos": ["https://example.com/video1.mp4"]
          },
          highlight: true,
          events: [
            {
              "title": "Public Meeting on Ward Development",
              "date": "15th December 2024, 6:00 PM",
              "description": "Open discussion on upcoming infrastructure projects and community needs"
            },
            {
              "title": "Youth Career Guidance Seminar",
              "date": "20th December 2024, 10:00 AM",
              "description": "Career counseling and skill development workshop for young adults"
            },
            {
              "title": "Senior Citizens Health Camp",
              "date": "25th December 2024, 9:00 AM",
              "description": "Free health checkup and consultation for senior citizens"
            },
            {
              "title": "Environmental Awareness Drive",
              "date": "30th December 2024, 8:00 AM",
              "description": "Tree plantation and cleanliness drive in the ward"
            }
          ]
        )
      );
    }

    // Add dummy manifesto if not present
    if (candidate.manifesto == null || candidate.manifesto!.isEmpty) {
      candidate = candidate.copyWith(
        manifesto: "Dear Fellow Citizens,\n\nI stand before you with a vision of progress, prosperity, and inclusive development for our beloved ward. My manifesto is built on three fundamental pillars:\n\n1. **Infrastructure Development**: Modern roads, efficient public transport, and sustainable urban planning.\n\n2. **Education & Healthcare**: Quality education for all children and accessible healthcare facilities.\n\n3. **Economic Empowerment**: Skill development programs, job creation initiatives, and support for local businesses.\n\n4. **Environmental Sustainability**: Green initiatives, waste management, and pollution control measures.\n\n5. **Social Welfare**: Support for senior citizens, women empowerment, and inclusive policies for all.\n\nTogether, we can build a ward that we can all be proud of. Your support and participation in this journey will be invaluable.\n\nLet's work together for a brighter future!\n\nBest regards,\n${candidate.name}",
        followersCount: 2500, // High follower count for premium demonstration
        followingCount: 45,
        sponsored: true, // Make sponsored for premium badge
      );
    }

    // Add dummy email if not present
    if (candidate.contact.email == null || candidate.contact.email!.isEmpty) {
      candidate = candidate.copyWith(
        contact: candidate.contact.copyWith(
          email: "${candidate.name.toLowerCase().replaceAll(' ', '.')}@gmail.com"
        )
      );
    }

    // Add dummy social links if not present
    if (candidate.contact.socialLinks == null || candidate.contact.socialLinks!.isEmpty) {
      candidate = candidate.copyWith(
        contact: candidate.contact.copyWith(
          socialLinks: {
            "Facebook": "https://facebook.com/${candidate.name.toLowerCase().replaceAll(' ', '')}",
            "Twitter": "https://twitter.com/${candidate.name.toLowerCase().replaceAll(' ', '')}",
            "Instagram": "https://instagram.com/${candidate.name.toLowerCase().replaceAll(' ', '')}",
            "YouTube": "https://youtube.com/${candidate.name.toLowerCase().replaceAll(' ', '')}",
            "Website": "https://www.${candidate.name.toLowerCase().replaceAll(' ', '')}.com"
          }
        )
      );
    }
  }

  // Get party symbol path
  String getPartySymbolPath(String party) {
    print('🔍 [Mapping Party Symbol] For party: $party');
    final partySymbols = {
      'Indian National Congress': 'assets/symbols/inc.png',
      'Bharatiya Janata Party': 'assets/symbols/bjp.png',
      'Nationalist Congress Party (Ajit Pawar faction)': 'assets/symbols/ncp_ajit.png',
      'Nationalist Congress Party – Sharadchandra Pawar': 'assets/symbols/ncp_sp.png',
      'Shiv Sena (Eknath Shinde faction)': 'assets/symbols/shiv_sena_shinde.png',
      'Shiv Sena (Uddhav Balasaheb Thackeray – UBT)': 'assets/symbols/shiv_sena_ubt.jpeg',
      'Maharashtra Navnirman Sena': 'assets/symbols/mns.png',
      'Communist Party of India': 'assets/symbols/cpi.png',
      'Communist Party of India (Marxist)': 'assets/symbols/cpi_m.png',
      'Bahujan Samaj Party': 'assets/symbols/bsp.png',
      'Samajwadi Party': 'assets/symbols/sp.png',
      'All India Majlis-e-Ittehad-ul-Muslimeen': 'assets/symbols/aimim.png',
      'National Peoples Party': 'assets/symbols/npp.png',
      'Peasants and Workers Party of India': 'assets/symbols/pwp.jpg',
      'Vanchit Bahujan Aaghadi': 'assets/symbols/vba.png',
      'Rashtriya Samaj Paksha': 'assets/symbols/default.png',
    };

    // First try exact match
    if (partySymbols.containsKey(party)) {
      return partySymbols[party]!;
    }

    // Try case-insensitive match
    final upperParty = party.toUpperCase();
    for (var entry in partySymbols.entries) {
      if (entry.key.toUpperCase() == upperParty) {
        return entry.value;
      }
    }

    // Try partial matches for common variations
    final partialMatches = {
      'INDIAN NATIONAL CONGRESS': 'assets/symbols/inc.png',
      'INDIA NATIONAL CONGRESS': 'assets/symbols/inc.png',
      'BHARATIYA JANATA PARTY': 'assets/symbols/bjp.png',
      'NATIONALIST CONGRESS PARTY': 'assets/symbols/ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY AJIT': 'assets/symbols/ncp_ajit.png',
      'NATIONALIST CONGRESS PARTY SP': 'assets/symbols/ncp_sp.png',
      'SHIV SENA': 'assets/symbols/shiv_sena_ubt.jpeg',
      'SHIV SENA UBT': 'assets/symbols/shiv_sena_ubt.jpeg',
      'SHIV SENA SHINDE': 'assets/symbols/shiv_sena_shinde.png',
      'MAHARASHTRA NAVNIRMAN SENA': 'assets/symbols/mns.png',
      'COMMUNIST PARTY OF INDIA': 'assets/symbols/cpi.png',
      'COMMUNIST PARTY OF INDIA MARXIST': 'assets/symbols/cpi_m.png',
      'BAHUJAN SAMAJ PARTY': 'assets/symbols/bsp.png',
      'SAMAJWADI PARTY': 'assets/symbols/sp.png',
      'ALL INDIA MAJLIS E ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
      'ALL INDIA MAJLIS-E-ITTEHADUL MUSLIMEEN': 'assets/symbols/aimim.png',
      'NATIONAL PEOPLES PARTY': 'assets/symbols/npp.png',
      'PEASANT AND WORKERS PARTY': 'assets/symbols/pwp.jpg',
      'VANCHIT BAHUJAN AGHADI': 'assets/symbols/vba.png',
      'REVOLUTIONARY SOCIALIST PARTY': 'assets/symbols/default.png',
    };

    for (var entry in partialMatches.entries) {
      if (upperParty.contains(entry.key.toUpperCase().replaceAll(' ', '')) ||
          entry.key.toUpperCase().contains(upperParty.replaceAll(' ', ''))) {
        return entry.value;
      }
    }

    return 'assets/symbols/default.png';
  }

  // Format date
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Check if candidate is premium (you can define your own logic here)
    bool isPremiumCandidate = candidate.sponsored || candidate.followersCount > 1000;

    // For demonstration, make this candidate premium
    isPremiumCandidate = true;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              ProfileHeader(
                candidate: candidate,
                isPremiumCandidate: isPremiumCandidate,
                getPartySymbolPath: getPartySymbolPath,
                formatDate: formatDate,
                buildStatItem: _buildStatItem,
              ),
            ];
          },
          body: TabBarView(
            children: [
              InfoTab(
                candidate: candidate,
                getPartySymbolPath: getPartySymbolPath,
                formatDate: formatDate,
              ),
              ManifestoTab(candidate: candidate),
              MediaTab(candidate: candidate),
              ContactTab(candidate: candidate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }


}
