import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/candidate_model.dart';

class ManifestoTab extends StatelessWidget {
  final Candidate candidate;

  const ManifestoTab({
    Key? key,
    required this.candidate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.manifesto != null && candidate.manifesto!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Manifesto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      if (candidate.extraInfo?.manifestoPdf != null && candidate.extraInfo!.manifestoPdf!.isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            final url = candidate.extraInfo!.manifestoPdf!;
                            if (await canLaunch(url)) {
                              await launch(url);
                            }
                          },
                          icon: const Icon(Icons.download, color: Colors.blue),
                          tooltip: 'Download PDF',
                        ),
                    ],
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
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No manifesto available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}