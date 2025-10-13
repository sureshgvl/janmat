import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/app_logger.dart';
import '../../../../services/plan_service.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';

class PromiseManagementSection extends StatefulWidget {
  final List<Map<String, dynamic>> promiseControllers;
  final Function(List<Map<String, dynamic>>) onPromisesChange;
  final bool isEditing;

  const PromiseManagementSection({
    super.key,
    required this.promiseControllers,
    required this.onPromisesChange,
    required this.isEditing,
  });

  @override
  State<PromiseManagementSection> createState() =>
      _PromiseManagementSectionState();
}

class _PromiseManagementSectionState extends State<PromiseManagementSection> {
  Future<void> _addNewPromise() async {
    AppLogger.candidate('Add New Promise button pressed');

    // Check if user can add more promises based on their plan
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final plan = await PlanService.getUserPlan(currentUser.uid);
      if (plan != null && plan.dashboardTabs?.manifesto.enabled == true) {
        final maxPromises = plan.dashboardTabs!.manifesto.features.maxPromises;
        final currentPromises = widget.promiseControllers.length;

        if (currentPromises >= maxPromises) {
          // Show upgrade message
          final localizations = CandidateLocalizations.of(context);
          if (localizations != null) {
            _showUpgradeDialog(
              localizations.translate('promiseLimitReached'),
              localizations.translate('promiseLimitMessage', args: {
                'count': maxPromises.toString(),
                'promiseText': maxPromises == 1
                    ? localizations.translate('promiseSingular')
                    : localizations.translate('promisePlural')
              }),
              localizations.translate('upgradeToGold'),
            );
          }
          return;
        }
      }
    }

    setState(() {
      final newController = <String, dynamic>{
        'title': TextEditingController(),
        'points': <TextEditingController>[TextEditingController()],
      };
      widget.promiseControllers.add(newController);
    });
    // Create updated promises list from controllers
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
    AppLogger.candidate(
      'Added new promise, total promises: ${widget.promiseControllers.length}',
    );
  }

  void _deletePromise(int index) {
    setState(() {
      widget.promiseControllers.removeAt(index);
    });
    // Create updated promises list from controllers
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
    AppLogger.candidate(
      'Deleted promise at index $index, remaining promises: ${widget.promiseControllers.length}',
    );
  }

  void _addPointToPromise(int promiseIndex) {
    AppLogger.candidate('Add Point button pressed for promise $promiseIndex');
    final pointsList =
        widget.promiseControllers[promiseIndex]['points']
            as List<TextEditingController>? ??
        [];

    setState(() {
      pointsList.add(TextEditingController());
      widget.promiseControllers[promiseIndex]['points'] = pointsList;
    });

    // Update the promise data through callback
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
    AppLogger.candidate(
      'Added point to promise $promiseIndex, total points: ${pointsList.length}',
    );
  }

  void _deletePointFromPromise(int promiseIndex, int pointIndex) {
    final pointsList =
        widget.promiseControllers[promiseIndex]['points']
            as List<TextEditingController>? ??
        [];

    setState(() {
      pointsList.removeAt(pointIndex);
      widget.promiseControllers[promiseIndex]['points'] = pointsList;
    });

    // Update the promise data through callback
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
  }

  void _onPromiseTitleChanged(int index, String value) {
    // Update the promise data through callback
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
  }

  void _onPromisePointChanged(int promiseIndex, int pointIndex, String value) {
    // Update the promise data through callback
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);
  }

  void _showDemoPromiseOptions(int promiseIndex) {
    String selectedLanguage = 'en'; // Default to English

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Choose Promise Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Selection
                Text(
                  'Select Language',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLanguage = 'en';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedLanguage == 'en'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          foregroundColor: selectedLanguage == 'en'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('English'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLanguage = 'mr';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedLanguage == 'mr'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          foregroundColor: selectedLanguage == 'mr'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('मराठी'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Template',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // English Templates
                if (selectedLanguage == 'en') ...[
                  ListTile(
                    title: Text('Clean Water Initiative'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Water supply and quality improvements'),
                        const SizedBox(height: 4),
                        Text(
                          '• 24x7 clean water to every household\n• Water purification systems\n• Quality testing & monitoring\n• Emergency water supply',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'Clean Water Initiative',
                        'points': [
                          'Provide 24x7 clean water to every household',
                          'Install water purification systems in all wards',
                          'Regular water quality testing and monitoring',
                          'Emergency water supply during shortages'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Road Infrastructure Development'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Road maintenance and construction'),
                        const SizedBox(height: 4),
                        Text(
                          '• Pothole-free ward roads in 1 year\n• New roads in developing areas\n• Improve street lighting\n• Regular maintenance schedules',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'Road Infrastructure Development',
                        'points': [
                          'Pothole-free ward roads in 1 year',
                          'Construct new roads in developing areas',
                          'Improve street lighting on all roads',
                          'Regular maintenance and repair schedules'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Healthcare Access'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Medical services and health programs'),
                        const SizedBox(height: 4),
                        Text(
                          '• Free health checkup camps monthly\n• 24x7 emergency medical services\n• Affordable medicine centers\n• Mobile clinics for remote areas',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'Healthcare Access',
                        'points': [
                          'Free health checkup camps every month',
                          '24x7 emergency medical services',
                          'Affordable medicine distribution centers',
                          'Mobile health clinics for remote areas'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Education Enhancement'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Digital classrooms and scholarships'),
                        const SizedBox(height: 4),
                        Text(
                          '• Digital classrooms in all schools\n• Free coaching for competitive exams\n• Library & study centers\n• Scholarship programs',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'Education Enhancement',
                        'points': [
                          'Digital classrooms in all schools',
                          'Free coaching classes for competitive exams',
                          'Library and study centers in every ward',
                          'Scholarship programs for meritorious students'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Waste Management'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Waste collection and recycling programs'),
                        const SizedBox(height: 4),
                        Text(
                          '• Door-to-door waste collection daily\n• Waste segregation & recycling\n• Clean and green campaigns\n• Zero waste ward by 2025',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'Waste Management',
                        'points': [
                          'Door-to-door waste collection daily',
                          'Waste segregation and recycling programs',
                          'Clean and green ward campaigns',
                          'Zero waste ward by 2025'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ]
                // Marathi Templates
                else ...[
                  ListTile(
                    title: Text('स्वच्छ पाणी उपक्रम'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('पाणी पुरवठा आणि गुणवत्ता सुधारणा'),
                        const SizedBox(height: 4),
                        Text(
                          '• प्रत्येक घराला 24x7 स्वच्छ पाणी\n• पाणी शुद्धीकरण प्रणाली\n• गुणवत्ता चाचणी आणि निरीक्षण\n• आपत्कालीन पाणी पुरवठा',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'स्वच्छ पाणी उपक्रम',
                        'points': [
                          'प्रत्येक घराला 24x7 स्वच्छ पाणी पुरवठा',
                          'सर्व प्रभागांमध्ये पाणी शुद्धीकरण प्रणाली बसवा',
                          'नियमित पाणी गुणवत्ता चाचणी आणि निरीक्षण',
                          'टंचाईच्या काळात आपत्कालीन पाणी पुरवठा'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('रस्ते पायाभूत सुविधा विकास'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('रस्ते देखभाल आणि बांधकाम'),
                        const SizedBox(height: 4),
                        Text(
                          '• 1 वर्षात खड्डे मुक्त प्रभाग रस्ते\n• विकासक्षेत्रात नवीन रस्ते\n• रस्ता प्रकाश व्यवस्था सुधारणा\n• नियमित देखभाल वेळापत्रक',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'रस्ते पायाभूत सुविधा विकास',
                        'points': [
                          '1 वर्षात खड्डे मुक्त प्रभाग रस्ते',
                          'विकासक्षेत्रात नवीन रस्ते बांधणी',
                          'सर्व रस्त्यांवर रस्ता प्रकाश व्यवस्था सुधारणा',
                          'नियमित देखभाल आणि दुरुस्ती वेळापत्रक'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('आरोग्य सेवा प्रवेश'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('वैद्यकीय सेवा आणि आरोग्य कार्यक्रम'),
                        const SizedBox(height: 4),
                        Text(
                          '• महिन्यातून मोफत आरोग्य तपासणी\n• 24x7 आपत्कालीन वैद्यकीय सेवा\n• परवडणाऱ्या औषध केंद्रे\n• मोबाईल आरोग्य क्लिनिक',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'आरोग्य सेवा प्रवेश',
                        'points': [
                          'महिन्यातून मोफत आरोग्य तपासणी शिबिरे',
                          '24x7 आपत्कालीन वैद्यकीय सेवा',
                          'परवडणाऱ्या औषध वितरण केंद्रे',
                          'दुर्गम भागांसाठी मोबाईल आरोग्य क्लिनिक'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('शिक्षण वृद्धी'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('डिजिटल वर्ग आणि शिष्यवृत्ती'),
                        const SizedBox(height: 4),
                        Text(
                          '• सर्व शाळांमध्ये डिजिटल वर्ग\n• स्पर्धा परीक्षांसाठी प्रशिक्षण\n• ग्रंथालय आणि अभ्यास केंद्रे\n• शिष्यवृत्ती कार्यक्रम',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'शिक्षण वृद्धी',
                        'points': [
                          'सर्व शाळांमध्ये डिजिटल वर्ग',
                          'स्पर्धा परीक्षांसाठी मोफत प्रशिक्षण वर्ग',
                          'प्रत्येक प्रभागात ग्रंथालय आणि अभ्यास केंद्रे',
                          'गुणवंत विद्यार्थ्यांसाठी शिष्यवृत्ती कार्यक्रम'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('कचरा व्यवस्थापन'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('कचरा संकलन आणि पुनर्वापर कार्यक्रम'),
                        const SizedBox(height: 4),
                        Text(
                          '• दररोज घरपोच कचरा संकलन\n• कचरा विलगीकरण आणि पुनर्वापर\n• स्वच्छ आणि हिरवे मोहिम\n• 2025 पर्यंत शून्य कचरा',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _populatePromiseWithData(promiseIndex, {
                        'title': 'कचरा व्यवस्थापन',
                        'points': [
                          'दररोज घरपोच कचरा संकलन',
                          'कचरा विलगीकरण आणि पुनर्वापर कार्यक्रम',
                          'स्वच्छ आणि हिरवे प्रभाग मोहिम',
                          '2025 पर्यंत शून्य कचरा प्रभाग'
                        ]
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _populatePromiseWithData(int promiseIndex, Map<String, dynamic> demoData) {
    AppLogger.candidate('Populating promise $promiseIndex with demo data: ${demoData['title']}');

    setState(() {
      // Update title
      final titleController = widget.promiseControllers[promiseIndex]['title'] as TextEditingController;
      titleController.text = demoData['title'] as String;

      // Update points
      final pointsList = widget.promiseControllers[promiseIndex]['points'] as List<TextEditingController>;
      final demoPoints = demoData['points'] as List<String>;

      // Clear existing points
      for (var controller in pointsList) {
        controller.dispose();
      }
      pointsList.clear();

      // Add new demo points
      for (var point in demoPoints) {
        pointsList.add(TextEditingController(text: point));
      }

      // Ensure at least one point exists
      if (pointsList.isEmpty) {
        pointsList.add(TextEditingController());
      }

      widget.promiseControllers[promiseIndex]['points'] = pointsList;
    });

    // Update the promise data through callback
    final updatedPromises = widget.promiseControllers.map((controller) {
      final title = (controller['title'] as TextEditingController).text;
      final points = (controller['points'] as List<TextEditingController>)
          .map((c) => c.text)
          .toList();
      return <String, dynamic>{'title': title, 'points': points};
    }).toList();
    widget.onPromisesChange(updatedPromises);

    AppLogger.candidate('Demo data populated for promise $promiseIndex: ${demoData['title']}');
  }

  void _showUpgradeDialog(String title, String message, String buttonText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to monetization screen
              // Get.to(() => const MonetizationScreen());
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.promises,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(widget.promiseControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Promise ${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                onPressed: () => _showDemoPromiseOptions(index),
                                tooltip: 'Use demo template',
                              ),
                              if (widget.promiseControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deletePromise(index),
                                  tooltip: 'Delete Promise',
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          // Promise Title
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: TextFormField(
                              controller:
                                  widget.promiseControllers[index]['title']
                                      as TextEditingController? ??
                                  TextEditingController(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Promise Title',
                                labelStyle: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(),
                                hintText: 'e.g., Clean Water and Good Roads',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (value) =>
                                  _onPromiseTitleChanged(index, value),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Promise Points
                          ...List.generate(
                            (widget.promiseControllers[index]['points']
                                        as List<TextEditingController>?)
                                    ?.length ??
                                0,
                            (pointIndex) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 24,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller:
                                            ((widget.promiseControllers[index]['points']
                                                as List<
                                                  TextEditingController
                                                >?) ??
                                            [])[pointIndex],
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Point ${pointIndex + 1}',
                                          labelStyle: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          border: const OutlineInputBorder(),
                                          hintText: pointIndex == 0
                                              ? 'Provide 24x7 clean water to every household'
                                              : 'Pothole-free ward roads in 1 year',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        onChanged: (value) =>
                                            _onPromisePointChanged(
                                              index,
                                              pointIndex,
                                              value,
                                            ),
                                      ),
                                    ),
                                    if (((widget.promiseControllers[index]['points']
                                                    as List<
                                                      TextEditingController
                                                    >?) ??
                                                [])
                                            .length >
                                        1)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _deletePointFromPromise(
                                              index,
                                              pointIndex,
                                            ),
                                        tooltip: 'Delete Point',
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Add Point Button
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () => _addPointToPromise(index),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(
                                  AppLocalizations.of(context)!.addPoint,
                                ),
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addNewPromise,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addNewPromise),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      // View mode - display promises
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.promisesTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          // TODO: Implement view mode for promises
          const Text('Promise view mode not implemented yet'),
        ],
      );
    }
  }
}

