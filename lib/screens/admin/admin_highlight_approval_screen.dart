import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/admin_highlight_service.dart';
import '../../services/highlight_service.dart';

class AdminHighlightApprovalScreen extends StatefulWidget {
  const AdminHighlightApprovalScreen({Key? key}) : super(key: key);

  @override
  _AdminHighlightApprovalScreenState createState() => _AdminHighlightApprovalScreenState();
}

class _AdminHighlightApprovalScreenState extends State<AdminHighlightApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Highlight> pendingHighlights = [];
  List<Highlight> activeHighlights = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() => isLoading = true);

    try {
      final pending = await AdminHighlightService.getPendingHighlights();
      final active = await AdminHighlightService.getAllActiveHighlights();

      setState(() {
        pendingHighlights = pending;
        activeHighlights = active;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading highlights: $e')),
      );
    }
  }

  Future<void> _approveHighlight(String highlightId) async {
    final success = await AdminHighlightService.approveHighlight(highlightId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Highlight approved successfully')),
      );
      _loadHighlights();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve highlight')),
      );
    }
  }

  Future<void> _rejectHighlight(String highlightId) async {
    final reason = await _showRejectionDialog();
    if (reason != null) {
      final success = await AdminHighlightService.rejectHighlight(highlightId, reason);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highlight rejected')),
        );
        _loadHighlights();
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    String reason = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Highlight'),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reason),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlight Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Active', icon: Icon(Icons.check_circle)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHighlights,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildActiveTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadHighlights,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh Data',
      ),
    );
  }

  Widget _buildPendingTab() {
    if (pendingHighlights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending highlights',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingHighlights.length,
      itemBuilder: (context, index) {
        final highlight = pendingHighlights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with candidate info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: highlight.imageUrl != null
                          ? NetworkImage(highlight.imageUrl!)
                          : null,
                      child: highlight.imageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            highlight.candidateName ?? 'Unknown Candidate',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            highlight.party ?? 'Unknown Party',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
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

                const SizedBox(height: 12),

                // Highlight details
                Text('Ward: ${highlight.wardId}'),
                Text('Placement: ${highlight.placement.join(", ")}'),
                Text('Priority: ${highlight.priority}'),
                Text('Duration: ${highlight.startDate.day}/${highlight.startDate.month} - ${highlight.endDate.day}/${highlight.endDate.month}'),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveHighlight(highlight.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectHighlight(highlight.id),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    if (activeHighlights.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active highlights',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeHighlights.length,
      itemBuilder: (context, index) {
        final highlight = activeHighlights[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: highlight.imageUrl != null
                  ? NetworkImage(highlight.imageUrl!)
                  : null,
              child: highlight.imageUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(highlight.candidateName ?? 'Unknown'),
            subtitle: Text('${highlight.wardId} • ${highlight.views} views • ${highlight.clicks} clicks'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(highlight),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () => _deactivateHighlight(highlight.id),
                  tooltip: 'Deactivate',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text('Analytics dashboard coming soon...'),
    );
  }

  Future<void> _deactivateHighlight(String highlightId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Highlight'),
        content: const Text('Are you sure you want to deactivate this highlight?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminHighlightService.deactivateHighlight(highlightId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highlight deactivated')),
        );
        _loadHighlights();
      }
    }
  }

  Future<void> _showEditDialog(Highlight highlight) async {
    int priority = highlight.priority;
    List<String> placement = List.from(highlight.placement);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Highlight'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Priority'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: priority.toString()),
                onChanged: (value) => priority = int.tryParse(value) ?? priority,
              ),
              const SizedBox(height: 16),
              const Text('Placement:'),
              CheckboxListTile(
                title: const Text('Carousel'),
                value: placement.contains('carousel'),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      placement.add('carousel');
                    } else {
                      placement.remove('carousel');
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Top Banner'),
                value: placement.contains('top_banner'),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      placement.add('top_banner');
                    } else {
                      placement.remove('top_banner');
                    }
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AdminHighlightService.updateHighlightPriority(highlight.id, priority);
                await AdminHighlightService.updateHighlightPlacement(highlight.id, placement);
                Navigator.pop(context);
                _loadHighlights();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}