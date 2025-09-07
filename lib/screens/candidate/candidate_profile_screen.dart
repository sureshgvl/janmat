import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/candidate_model.dart';

class CandidateProfileScreen extends StatelessWidget {
  const CandidateProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Candidate candidate = Get.arguments as Candidate;

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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      candidate.sponsored ? Colors.amber.shade400 : Colors.blue.shade400,
                      candidate.sponsored ? Colors.amber.shade600 : Colors.blue.shade600,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background Pattern
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          getPartySymbolPath(candidate.party),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Candidate Photo
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: candidate.photo != null && candidate.photo!.isNotEmpty
                                  ? Image.network(
                                      candidate.photo!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return CircleAvatar(
                                          backgroundColor: candidate.sponsored ? Colors.amber : Colors.blue,
                                          child: Text(
                                            candidate.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : CircleAvatar(
                                      backgroundColor: candidate.sponsored ? Colors.amber : Colors.blue,
                                      child: Text(
                                        candidate.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            candidate.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            actions: [
              if (candidate.sponsored)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'SPONSORED',
                        style: TextStyle(
                          color: Color(0xFF92400e),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Party Information
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(getPartySymbolPath(candidate.party)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.party,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1f2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ward ${candidate.wardId} • ${candidate.cityId}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6b7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contact Information
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.phone,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Phone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6b7280),
                                    ),
                                  ),
                                  Text(
                                    candidate.contact.phone,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1f2937),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (candidate.contact.email != null && candidate.contact.email!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.email,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6b7280),
                                      ),
                                    ),
                                    Text(
                                      candidate.contact.email!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1f2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Manifesto
                  if (candidate.manifesto != null && candidate.manifesto!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manifesto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            candidate.manifesto!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Bio (if available)
                  if (candidate.extraInfo?.bio != null && candidate.extraInfo!.bio!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            candidate.extraInfo!.bio!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Achievements (if available)
                  if (candidate.extraInfo?.achievements != null && candidate.extraInfo!.achievements!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...candidate.extraInfo!.achievements!.map((achievement) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    achievement,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF374151),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
