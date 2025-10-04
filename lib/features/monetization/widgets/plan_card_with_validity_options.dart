import 'package:flutter/material.dart';
import '../../../models/plan_model.dart';

class PlanCardWithValidityOptions extends StatefulWidget {
  final SubscriptionPlan plan;
  final String electionType;
  final Function(SubscriptionPlan, int) onPurchase;
  final bool compactMode;

  const PlanCardWithValidityOptions({
    required this.plan,
    required this.electionType,
    required this.onPurchase,
    this.compactMode = false,
    super.key,
  });

  @override
  State<PlanCardWithValidityOptions> createState() => _PlanCardWithValidityOptionsState();
}

class _PlanCardWithValidityOptionsState extends State<PlanCardWithValidityOptions> {
  int? selectedValidityDays;

  @override
  Widget build(BuildContext context) {
    // Get election type if not provided (for compact mode)
    final electionType = widget.electionType.isNotEmpty ? widget.electionType :
      'municipal_corporation'; // Default fallback

    final pricing = widget.plan.pricing[electionType];
    if (pricing == null || pricing.isEmpty) {
      return const SizedBox.shrink(); // Don't show plans without pricing
    }

    final validityOptions = pricing.keys.toList()..sort();

    if (widget.compactMode) {
      // Compact mode - validity options with features
      return Column(
        children: [
          // Plan Header with badges
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.plan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (widget.plan.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Key Features - Compact version
          const Text('Key Features:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          ..._buildCompactFeaturesList().take(3), // Show only top 3 features

          const SizedBox(height: 8),

          // Validity Period Selection
          const Text('Select Validity Period:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),

          // Validity Options - Compact version
          ...validityOptions.map((days) {
            final price = pricing[days]!;
            final isSelected = selectedValidityDays == days;

            return GestureDetector(
              onTap: () => setState(() => selectedValidityDays = days),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: isSelected ? Colors.blue.shade50 : Colors.white,
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: days,
                      groupValue: selectedValidityDays,
                      onChanged: (value) => setState(() => selectedValidityDays = value),
                      activeColor: Colors.blue,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: Text(
                        '$days Days - ₹$price',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.blue : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Attractive Purchase Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: selectedValidityDays != null
                ? LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selectedValidityDays != null
                ? [
                    BoxShadow(
                      color: Colors.blue.shade300.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            ),
            child: ElevatedButton(
              onPressed: selectedValidityDays != null
                ? () => widget.onPurchase(widget.plan, selectedValidityDays!)
                : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedValidityDays != null) ...[
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    selectedValidityDays != null
                      ? 'Purchase for ₹${pricing[selectedValidityDays!]!}'
                      : 'Select validity period',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Full mode - with card wrapper and features
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.plan.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Features List
              const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._buildFeaturesList(),

              const SizedBox(height: 16),

              // Validity Period Selection
              const Text('Select Validity Period:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Validity Options
              Column(
                children: validityOptions.map((days) {
                  final price = pricing[days]!;
                  final isSelected = selectedValidityDays == days;

                  return GestureDetector(
                    onTap: () => setState(() => selectedValidityDays = days),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Radio<int>(
                            value: days,
                            groupValue: selectedValidityDays,
                            onChanged: (value) => setState(() => selectedValidityDays = value),
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$days Days',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Valid until ${DateTime.now().add(Duration(days: days)).toString().split(' ')[0]}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹$price', // Price in rupees (no division needed)
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.blue : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedValidityDays != null
                    ? () => widget.onPurchase(widget.plan, selectedValidityDays!)
                    : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: selectedValidityDays != null ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    selectedValidityDays != null
                      ? 'Purchase for ₹${pricing[selectedValidityDays!]!}'
                      : 'Select validity period',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  List<Widget> _buildFeaturesList() {
    final features = <Widget>[];

    // Dashboard Tabs Features
    if (widget.plan.dashboardTabs.basicInfo.enabled) {
      features.add(_buildFeatureItem('✓ Basic Info'));
    }

    if (widget.plan.dashboardTabs.manifesto.enabled) {
      features.add(_buildFeatureItem('✓ Manifesto'));
      if (widget.plan.dashboardTabs.manifesto.features.pdfUpload) {
        features.add(_buildFeatureItem('  • PDF Upload'));
      }
      if (widget.plan.dashboardTabs.manifesto.features.videoUpload) {
        features.add(_buildFeatureItem('  • Video Upload'));
      }
    }

    if (widget.plan.dashboardTabs.achievements.enabled) {
      final max = widget.plan.dashboardTabs.achievements.maxAchievements == -1 ? 'Unlimited' : widget.plan.dashboardTabs.achievements.maxAchievements.toString();
      features.add(_buildFeatureItem('✓ Achievements ($max)'));
    }

    if (widget.plan.dashboardTabs.media.enabled) {
      final max = widget.plan.dashboardTabs.media.maxMediaItems == -1 ? 'Unlimited' : widget.plan.dashboardTabs.media.maxMediaItems.toString();
      features.add(_buildFeatureItem('✓ Media ($max items)'));
    }

    if (widget.plan.dashboardTabs.contact.enabled) {
      features.add(_buildFeatureItem('✓ Contact'));
    }

    if (widget.plan.dashboardTabs.events.enabled) {
      final max = widget.plan.dashboardTabs.events.maxEvents == -1 ? 'Unlimited' : widget.plan.dashboardTabs.events.maxEvents.toString();
      features.add(_buildFeatureItem('✓ Events ($max)'));
    }

    if (widget.plan.dashboardTabs.analytics.enabled) {
      features.add(_buildFeatureItem('✓ Analytics'));
    }

    // Profile Features
    if (widget.plan.profileFeatures.premiumBadge) {
      features.add(_buildFeatureItem('✓ Premium Badge'));
    }
    if (widget.plan.profileFeatures.sponsoredBanner) {
      features.add(_buildFeatureItem('✓ Sponsored Banner'));
    }
    if (widget.plan.profileFeatures.highlightCarousel) {
      features.add(_buildFeatureItem('✓ Highlight Carousel'));
    }

    return features;
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  List<Widget> _buildCompactFeaturesList() {
    final features = <Widget>[];

    // Dashboard Tabs Features - Compact version
    if (widget.plan.dashboardTabs.basicInfo.enabled) {
      features.add(_buildCompactFeatureItem('✓ Basic Info'));
    }

    if (widget.plan.dashboardTabs.manifesto.enabled) {
      features.add(_buildCompactFeatureItem('✓ Manifesto'));
    }

    if (widget.plan.dashboardTabs.media.enabled) {
      features.add(_buildCompactFeatureItem('✓ Media Upload'));
    }

    if (widget.plan.dashboardTabs.analytics.enabled) {
      features.add(_buildCompactFeatureItem('✓ Analytics'));
    }

    if (widget.plan.dashboardTabs.achievements.enabled) {
      features.add(_buildCompactFeatureItem('✓ Achievements'));
    }

    if (widget.plan.dashboardTabs.contact.enabled) {
      features.add(_buildCompactFeatureItem('✓ Contact'));
    }

    if (widget.plan.dashboardTabs.events.enabled) {
      features.add(_buildCompactFeatureItem('✓ Events'));
    }

    // Profile Features - Compact version
    if (widget.plan.profileFeatures.premiumBadge) {
      features.add(_buildCompactFeatureItem('✓ Premium Badge'));
    }

    if (widget.plan.profileFeatures.sponsoredBanner) {
      features.add(_buildCompactFeatureItem('✓ Sponsored Banner'));
    }

    if (widget.plan.profileFeatures.highlightCarousel) {
      features.add(_buildCompactFeatureItem('✓ Highlight Carousel'));
    }

    return features;
  }

  Widget _buildCompactFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}

