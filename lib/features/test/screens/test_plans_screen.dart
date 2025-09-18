import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/plan_service.dart';

class TestPlansScreen extends StatefulWidget {
  const TestPlansScreen({Key? key}) : super(key: key);

  @override
  _TestPlansScreenState createState() => _TestPlansScreenState();
}

class _TestPlansScreenState extends State<TestPlansScreen> {
  List<Plan> plans = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? rawData;

  @override
  void initState() {
    super.initState();
    _loadPlans();
    _testRawData();
  }

  Future<void> _loadPlans() async {
    try {
      final fetchedPlans = await PlanService.getAllPlans();
      setState(() {
        plans = fetchedPlans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading plans: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _testRawData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('plans')
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          rawData = snapshot.docs.first.data();
        });
      }
    } catch (e) {
      print('Error fetching raw data: $e');
    }
  }

  Future<void> _testSpecificPlan() async {
    try {
      final plan = await PlanService.getPlanById('basic_plan');
      if (plan != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Found plan: ${plan.name} - ₹${plan.price}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = '';
              });
              _loadPlans();
            },
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
                        onPressed: _loadPlans,
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
                                'Plans Found: ${plans.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Firebase Connection: ✅ Working'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Test Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _testSpecificPlan,
                              child: const Text('Test Basic Plan'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loadPlans,
                              child: const Text('Refresh Plans'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Plans List
                      const Text(
                        'All Plans:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      ...plans.map((plan) => Card(
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
                                    plan.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${plan.price}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('ID: ${plan.planId}'),
                              Text('Type: ${plan.type}'),
                              if (plan.validityDays != null)
                                Text('Validity: ${plan.validityDays} days'),
                              Text('Features: ${plan.features.length}'),
                              Text('Active: ${plan.isActive ? 'Yes' : 'No'}'),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 16),

                      // Raw Data View
                      if (rawData != null) ...[
                        const Text(
                          'Raw Firebase Data (First Plan):',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              rawData.toString(),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
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