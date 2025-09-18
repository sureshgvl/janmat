import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/highlight_service.dart';

class TestHighlightsScreen extends StatefulWidget {
  const TestHighlightsScreen({Key? key}) : super(key: key);

  @override
  _TestHighlightsScreenState createState() => _TestHighlightsScreenState();
}

class _TestHighlightsScreenState extends State<TestHighlightsScreen> {
  List<Highlight> highlights = [];
  Highlight? platinumBanner;
  List<PushFeedItem> pushFeed = [];
  bool isLoading = true;
  String errorMessage = '';
  String testDistrictId = 'Pune'; // Test district
  String testBodyId = 'pune_city'; // Test body
  String testWardId = 'ward_pune_1'; // Test ward

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Load highlights
      final loadedHighlights = await HighlightService.getActiveHighlights(
        testDistrictId,
        testBodyId,
        testWardId,
      );

      // Load platinum banner
      final banner = await HighlightService.getPlatinumBanner(
        testDistrictId,
        testBodyId,
        testWardId,
      );

      // Load push feed
      final feed = await HighlightService.getPushFeed(testWardId, limit: 10);

      setState(() {
        highlights = loadedHighlights;
        platinumBanner = banner;
        pushFeed = feed;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _createTestHighlight() async {
    try {
      final highlightId = await HighlightService.createHighlight(
        candidateId: 'test_candidate_123',
        wardId: testWardId,
        districtId: testDistrictId,
        bodyId: testBodyId,
        package: 'gold',
        placement: ['carousel'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        imageUrl: 'https://example.com/test-image.jpg',
        candidateName: 'Test Candidate',
        party: 'Test Party',
      );

      if (highlightId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created highlight: $highlightId')),
        );
        _loadAllData(); // Refresh data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createTestPushFeed() async {
    try {
      final feedId = await HighlightService.createPushFeedItem(
        candidateId: 'test_candidate_123',
        wardId: testWardId,
        title: 'Test Sponsored Post',
        message: 'This is a test sponsored message for the push feed.',
        imageUrl: 'https://example.com/test-feed-image.jpg',
      );

      if (feedId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created push feed item: $feedId')),
        );
        _loadAllData(); // Refresh data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _testImpressionTracking() async {
    if (highlights.isNotEmpty) {
      await HighlightService.trackImpression(highlights.first.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracked impression for first highlight')),
      );
      _loadAllData(); // Refresh to see updated views
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Highlights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Location: $testDistrictId → $testBodyId → $testWardId',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Highlights Found: ${highlights.length}'),
                              Text('Platinum Banner: ${platinumBanner != null ? 'Yes' : 'No'}'),
                              Text('Push Feed Items: ${pushFeed.length}'),
                              const Text('Firebase Connection: ✅ Working'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Test Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _createTestHighlight,
                            icon: const Icon(Icons.add),
                            label: const Text('Create Test Highlight'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _createTestPushFeed,
                            icon: const Icon(Icons.feed),
                            label: const Text('Create Push Feed'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _testImpressionTracking,
                            icon: const Icon(Icons.visibility),
                            label: const Text('Track Impression'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Platinum Banner Section
                      if (platinumBanner != null) ...[
                        const Text(
                          'Platinum Banner:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID: ${platinumBanner!.id}'),
                                Text('Candidate: ${platinumBanner!.candidateName}'),
                                Text('Party: ${platinumBanner!.party}'),
                                Text('Views: ${platinumBanner!.views}'),
                                Text('Clicks: ${platinumBanner!.clicks}'),
                                Text('Active: ${platinumBanner!.active ? 'Yes' : 'No'}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Highlights List
                      const Text(
                        'Active Highlights:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...highlights.map((highlight) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    highlight.candidateName ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: highlight.package == 'gold'
                                          ? Colors.amber
                                          : Colors.purple,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      highlight.package.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${highlight.id}'),
                              Text('Party: ${highlight.party}'),
                              Text('Placement: ${highlight.placement.join(", ")}'),
                              Text('Views: ${highlight.views} | Clicks: ${highlight.clicks}'),
                              Text('Priority: ${highlight.priority}'),
                              Text('Active: ${highlight.active ? 'Yes' : 'No'}'),
                              Text('Exclusive: ${highlight.exclusive ? 'Yes' : 'No'}'),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 16),

                      // Push Feed List
                      const Text(
                        'Push Feed Items:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...pushFeed.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.isSponsored) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'SPONSORED',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item.message),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${item.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                      // Empty states
                      if (highlights.isEmpty && platinumBanner == null && pushFeed.isEmpty) ...[
                        const SizedBox(height: 32),
                        const Center(
                          child: Text(
                            'No highlight data found.\nCreate test data using the buttons above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}