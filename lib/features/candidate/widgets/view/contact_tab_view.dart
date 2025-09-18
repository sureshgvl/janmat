import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/candidate_model.dart';

class ContactTab extends StatefulWidget {
  final Candidate candidate;

  const ContactTab({super.key, required this.candidate});

  @override
  State<ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<ContactTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.contact_phone_outlined,
                        color: Colors.purple.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.phone,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6b7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.candidate.contact.phone,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: widget.candidate.contact.phone,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          }
                        },
                        icon: Icon(
                          Icons.call,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.candidate.contact.email != null &&
                    widget.candidate.contact.email!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.email,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6b7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.candidate.contact.email!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1f2937),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final Uri launchUri = Uri(
                              scheme: 'mailto',
                              path: widget.candidate.contact.email,
                            );
                            if (await canLaunchUrl(launchUri)) {
                              await launchUrl(launchUri);
                            }
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Social Links
          if (widget.candidate.contact.socialLinks != null &&
              widget.candidate.contact.socialLinks!.isNotEmpty) ...[
            const SizedBox(height: 20),
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
                  const Text(
                    'Social Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.candidate.contact.socialLinks!.entries.map(
                      (entry) {
                        return InkWell(
                          onTap: () async {
                            final url = entry.value;
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSocialIcon(entry.key),
                                  size: 16,
                                  color: Colors.blue.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
      case 'x':
        return Icons.alternate_email; // X/Twitter icon
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.business;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }
}
