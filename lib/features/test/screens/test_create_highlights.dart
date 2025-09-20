import 'package:flutter/material.dart';
import '../../../services/highlight_service.dart';
import 'test_highlights_screen.dart';

class TestCreateHighlightsScreen extends StatefulWidget {
  const TestCreateHighlightsScreen({super.key});

  @override
  _TestCreateHighlightsScreenState createState() =>
      _TestCreateHighlightsScreenState();
}

class _TestCreateHighlightsScreenState
    extends State<TestCreateHighlightsScreen> {
  final TextEditingController _candidateIdController = TextEditingController(
    text: 'test_candidate_123',
  );
  final TextEditingController _wardIdController = TextEditingController(
    text: 'ward_pune_1',
  );
  final TextEditingController _districtIdController = TextEditingController(
    text: 'Pune',
  );
  final TextEditingController _bodyIdController = TextEditingController(
    text: 'pune_city',
  );
  final TextEditingController _candidateNameController = TextEditingController(
    text: 'Rajesh Sharma',
  );
  final TextEditingController _partyController = TextEditingController(
    text: 'BJP',
  );
  final TextEditingController _imageUrlController = TextEditingController(
    text: 'https://picsum.photos/400/300?random=1',
  );

  String _selectedPackage = 'gold';
  final List<String> _selectedPlacement = ['carousel'];
  bool _isExclusive = false;
  bool _isCreating = false;

  final List<String> _packages = ['gold', 'platinum'];
  final List<String> _placementOptions = ['carousel', 'top_banner'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test Highlights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => _navigateToHighlightsList(),
            tooltip: 'View Highlights',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Test Highlight',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use this form to create test highlights for development and testing.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Basic Information
            _buildSectionHeader('Basic Information'),
            _buildTextField(_candidateIdController, 'Candidate ID'),
            _buildTextField(_wardIdController, 'Ward ID'),
            _buildTextField(_districtIdController, 'District ID'),
            _buildTextField(_bodyIdController, 'Body ID'),
            _buildTextField(_candidateNameController, 'Candidate Name'),
            _buildTextField(_partyController, 'Party'),
            _buildTextField(_imageUrlController, 'Image URL'),

            const SizedBox(height: 24),

            // Package Selection
            _buildSectionHeader('Package & Placement'),
            DropdownButtonFormField<String>(
              initialValue: _selectedPackage,
              decoration: const InputDecoration(
                labelText: 'Package',
                border: OutlineInputBorder(),
              ),
              items: _packages.map((package) {
                return DropdownMenuItem(
                  value: package,
                  child: Text(package.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedPackage = value!);
              },
            ),

            const SizedBox(height: 16),

            // Placement Options
            const Text(
              'Placement Options:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            ..._placementOptions.map((option) {
              return CheckboxListTile(
                title: Text(_getPlacementDisplayName(option)),
                value: _selectedPlacement.contains(option),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPlacement.add(option);
                    } else {
                      _selectedPlacement.remove(option);
                    }
                  });
                },
              );
            }),

            // Exclusive Option (Platinum only)
            if (_selectedPackage == 'platinum') ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Exclusive Banner'),
                subtitle: const Text('Reserve exclusive top banner spot'),
                value: _isExclusive,
                onChanged: (value) => setState(() => _isExclusive = value),
              ),
            ],

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createHighlight,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedPackage == 'platinum'
                      ? Colors.purple
                      : Colors.amber,
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create ${_selectedPackage.toUpperCase()} Highlight',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Test Buttons
            _buildSectionHeader('Quick Test Options'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createQuickGoldHighlight(),
                    icon: const Icon(Icons.star),
                    label: const Text('Quick Gold'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createQuickPlatinumHighlight(),
                    icon: const Icon(Icons.diamond),
                    label: const Text('Quick Platinum'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _createMultipleHighlights(),
              icon: const Icon(Icons.add_circle),
              label: const Text('Create 3 Test Highlights'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  String _getPlacementDisplayName(String placement) {
    switch (placement) {
      case 'carousel':
        return 'Highlight Carousel';
      case 'top_banner':
        return 'Top Banner (Platinum)';
      default:
        return placement;
    }
  }

  Future<void> _createHighlight() async {
    if (_candidateIdController.text.isEmpty || _wardIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Candidate ID and Ward ID'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final highlightId = await HighlightService.createHighlight(
        candidateId: _candidateIdController.text,
        wardId: _wardIdController.text,
        districtId: _districtIdController.text,
        bodyId: _bodyIdController.text,
        package: _selectedPackage,
        placement: _selectedPlacement,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        candidateName: _candidateNameController.text.isNotEmpty
            ? _candidateNameController.text
            : null,
        party: _partyController.text.isNotEmpty ? _partyController.text : null,
        exclusive: _isExclusive,
      );

      if (highlightId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Highlight created successfully! ID: $highlightId'),
          ),
        );

        // Navigate to highlights list to see the result
        _navigateToHighlightsList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create highlight')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _createQuickGoldHighlight() async {
    setState(() => _isCreating = true);

    try {
      final highlightId = await HighlightService.createHighlight(
        candidateId: 'quick_gold_candidate',
        wardId: _wardIdController.text,
        districtId: _districtIdController.text,
        bodyId: _bodyIdController.text,
        package: 'gold',
        placement: ['carousel'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        candidateName: 'Quick Gold Candidate',
        party: 'Test Party',
      );

      if (highlightId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick Gold highlight created!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating quick highlight: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _createQuickPlatinumHighlight() async {
    setState(() => _isCreating = true);

    try {
      final highlightId = await HighlightService.createHighlight(
        candidateId: 'quick_platinum_candidate',
        wardId: _wardIdController.text,
        districtId: _districtIdController.text,
        bodyId: _bodyIdController.text,
        package: 'platinum',
        placement: ['carousel', 'top_banner'],
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        candidateName: 'Quick Platinum Candidate',
        party: 'Premium Party',
        exclusive: true,
      );

      if (highlightId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick Platinum highlight created!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating quick highlight: $e')),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _createMultipleHighlights() async {
    setState(() => _isCreating = true);

    final candidates = [
      {'name': 'Rahul Gandhi', 'party': 'INC', 'id': 'candidate_rahul'},
      {'name': 'Narendra Modi', 'party': 'BJP', 'id': 'candidate_modi'},
      {'name': 'Arvind Kejriwal', 'party': 'AAP', 'id': 'candidate_kejriwal'},
    ];

    int successCount = 0;

    for (final candidate in candidates) {
      try {
        final highlightId = await HighlightService.createHighlight(
          candidateId: candidate['id']!,
          wardId: _wardIdController.text,
          districtId: _districtIdController.text,
          bodyId: _bodyIdController.text,
          package: 'gold',
          placement: ['carousel'],
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 7)),
          candidateName: candidate['name'],
          party: candidate['party'],
        );

        if (highlightId != null) successCount++;
      } catch (e) {
        print('Error creating highlight for ${candidate['name']}: $e');
      }
    }

    setState(() => _isCreating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created $successCount test highlights!')),
    );

    if (successCount > 0) {
      _navigateToHighlightsList();
    }
  }

  void _navigateToHighlightsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestHighlightsScreen()),
    );
  }

  @override
  void dispose() {
    _candidateIdController.dispose();
    _wardIdController.dispose();
    _districtIdController.dispose();
    _bodyIdController.dispose();
    _candidateNameController.dispose();
    _partyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}
