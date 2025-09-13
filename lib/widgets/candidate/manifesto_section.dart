import 'dart:io';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/candidate_model.dart';
import '../../services/file_upload_service.dart';
import '../../services/video_processing_service.dart';
import '../../models/video_metadata_model.dart';
import '../common/aspect_ratio_image.dart';

class ManifestoSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onManifestoChange;
  final Function(String) onManifestoPdfChange;
  final Function(String) onManifestoTitleChange;
  final Function(List<Map<String, dynamic>>) onManifestoPromisesChange;
  final Function(String) onManifestoImageChange;
  final Function(String) onManifestoVideoChange;

  const ManifestoSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onManifestoChange,
    required this.onManifestoPdfChange,
    required this.onManifestoTitleChange,
    required this.onManifestoPromisesChange,
    required this.onManifestoImageChange,
    required this.onManifestoVideoChange,
  });

  @override
  State<ManifestoSection> createState() => ManifestoSectionState();
}

class ManifestoSectionState extends State<ManifestoSection> {
  final GoogleTranslator _translator = GoogleTranslator();
  final FileUploadService _fileUploadService = FileUploadService();
  late TextEditingController _manifestoController;
  late TextEditingController _titleController;
  late List<Map<String, dynamic>> _promiseControllers;
  String _currentLanguage = 'en'; // 'en' for English, 'mr' for Marathi
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isUploadingPdf = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  String? _originalText;

  // Local storage tracking
  List<Map<String, dynamic>> _localFiles = []; // [{type: 'pdf/image/video', localPath: '...', fileName: '...'}]

  @override
  void initState() {
    super.initState();
    debugPrint('ManifestoSection initState called');
    final data = widget.editedData ?? widget.candidateData;
    _originalText = data.extraInfo?.manifesto?.title ?? '';
    _translatedText = _originalText ?? '';
    _manifestoController = TextEditingController(text: _originalText);

    // Initialize title controller with model data
    final manifestoTitle = data.extraInfo?.manifesto?.title ?? '';
    _titleController = TextEditingController(text: _stripBoldMarkers(manifestoTitle));

    // Initialize manifesto promises list with structured format from model
    final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
    debugPrint('Raw promises from data: $rawPromises');
    final manifestoPromises = rawPromises.map((promise) {
      if (promise is Map<String, dynamic>) {
        // Already structured format
        return promise;
      } else {
        // Convert string format to structured format (avoid duplicating title as a point)
        return <String, dynamic>{'title': promise.toString(), 'points': <dynamic>[]};
      }
    }).cast<Map<String, dynamic>>().toList();

    // Initialize controllers for existing promises
    _promiseControllers = manifestoPromises.map((promise) {
      final title = promise['title'] as String? ?? '';
      final points = promise['points'] as List<dynamic>? ?? <dynamic>[];
      return <String, dynamic>{
        'title': TextEditingController(text: _stripBoldMarkers(title)),
        'points': points.map((point) => TextEditingController(text: _stripBoldMarkers(point.toString()))).toList(),
      };
    }).toList();

    // If no promises exist, create one empty promise
    if (manifestoPromises.isEmpty) {
      debugPrint('No promises found, creating empty promise');
      _promiseControllers.add(<String, dynamic>{
        'title': TextEditingController(),
        'points': <TextEditingController>[TextEditingController()],
      });
    }
    debugPrint('Initialized with ${manifestoPromises.length} promises');
  }

  @override
  void didUpdateWidget(ManifestoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('ManifestoSection didUpdateWidget called, isEditing: ${widget.isEditing}');
    final data = widget.editedData ?? widget.candidateData;
    final newText = data.extraInfo?.manifesto?.title ?? '';
    if (_originalText != newText) {
      debugPrint('Updating original text from $_originalText to $newText');
      _originalText = newText;
      _manifestoController.text = newText;
      if (_currentLanguage == 'en') {
        _translatedText = newText;
      } else {
        _translateText(newText, _currentLanguage);
      }
    }

    // Update title controller with model data
    final newTitle = data.extraInfo?.manifesto?.title ?? '';
    _titleController.text = _stripBoldMarkers(newTitle);

    // Only update promises if we're not in editing mode or if the data has actually changed
    if (!widget.isEditing) {
      final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
      debugPrint('Raw promises in didUpdateWidget: $rawPromises');
      final newManifestoPromises = rawPromises.map((promise) {
        if (promise is Map<String, dynamic>) {
          // Already structured format
          return promise;
        } else {
          // Convert string format to structured format (avoid duplicating title as a point)
          return <String, dynamic>{'title': promise.toString(), 'points': <dynamic>[]};
        }
      }).cast<Map<String, dynamic>>().toList();

      // Update controllers with new data
      _promiseControllers = newManifestoPromises.map((promise) {
        final title = promise['title'] as String? ?? '';
        final points = promise['points'] as List<dynamic>? ?? <dynamic>[];
        return <String, dynamic>{
          'title': TextEditingController(text: _stripBoldMarkers(title)),
          'points': points.map((point) => TextEditingController(text: _stripBoldMarkers(point.toString()))).toList(),
        };
      }).toList();

      // If no promises exist, create one empty promise
      if (newManifestoPromises.isEmpty) {
        debugPrint('No promises found in didUpdateWidget, creating empty promise');
        _promiseControllers.add(<String, dynamic>{
          'title': TextEditingController(),
          'points': <TextEditingController>[TextEditingController()],
        });
      }
    } else {
      debugPrint('In editing mode, skipping promise updates');
    }
  }

  bool _arePromisesEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['title'] != list2[i]['title']) return false;
      final points1 = list1[i]['points'] as List<dynamic>? ?? [];
      final points2 = list2[i]['points'] as List<dynamic>? ?? [];
      if (points1.length != points2.length) return false;
      for (int j = 0; j < points1.length; j++) {
        if (points1[j].toString() != points2[j].toString()) return false;
      }
    }
    return true;
  }

  // Remove duplicates, empties, and title-duplicates from points for display
  List<String> _filteredPoints(dynamic points, String? title) {
    final String titleTrim = _stripBoldMarkers((title ?? '').trim());
    final List<String> result = [];
    if (points is List) {
      for (final p in points) {
        final s = _stripBoldMarkers(p?.toString() ?? '');
        if (s.isEmpty) continue;
        if (s == titleTrim) continue;
        if (!result.contains(s)) {
          result.add(s);
        }
      }
    }
    return result;
  }

  // Strip simple markdown bold markers for display
  String _stripBoldMarkers(String s) {
    if (s.isEmpty) return s;
    // Remove any ** surrounding markers and any standalone occurrences
    final trimmed = s.trim();
    if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length >= 4) {
      return trimmed.substring(2, trimmed.length - 2).trim();
    }
    return trimmed.replaceAll('**', '').trim();
  }

  // Ensure title text has ** markers for editing fields
  String _withBoldMarkers(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('**') && t.endsWith('**') && t.length >= 4) return t;
    return '**$t**';
  }

  @override
  void dispose() {
    _manifestoController.dispose();
    _titleController.dispose();
    for (var controllerMap in _promiseControllers) {
      (controllerMap['title'] as TextEditingController?)?.dispose();
      for (var pointController in (controllerMap['points'] as List<TextEditingController>? ?? [])) {
        pointController.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _translateText(String text, String targetLanguage) async {
    if (text.isEmpty) {
      setState(() {
        _translatedText = text;
        _isTranslating = false;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final translation = await _translator.translate(
        text,
        from: 'auto',
        to: targetLanguage,
      );

      if (mounted) {
        setState(() {
          _translatedText = translation.text;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedText = text; // Fallback to original text
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Translation failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _changeLanguage(String language) {
    if (_currentLanguage == language) return;

    setState(() {
      _currentLanguage = language;
    });

    if (_originalText != null) {
      if (language == 'en') {
        // Show original text (assuming original is English)
        setState(() {
          _translatedText = _originalText!;
        });
      } else {
        _translateText(_originalText!, language);
      }
    }
  }

  void _showDemoTitleOptions() {
    String selectedLanguage = 'en'; // Default to English
    final cityId = widget.candidateData.districtId;
    final wardId = widget.candidateData.wardId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Choose Manifesto Title'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Selection
                const Text(
                  'Select Language:',
                  style: TextStyle(
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
                const Text(
                  'Choose Title:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // English Titles
                if (selectedLanguage == 'en') ...[
                  ListTile(
                    title: Text('Ward $wardId Development Plan'),
                    subtitle: const Text('Standard development focus'),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Development Plan';
                      widget.onManifestoTitleChange('Ward $wardId Development Plan');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Development & Transparency Plan'),
                    subtitle: const Text('Development with transparency focus'),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Development & Transparency Plan';
                      widget.onManifestoTitleChange('Ward $wardId Development & Transparency Plan');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Progress Manifesto'),
                    subtitle: const Text('Focus on progress and growth'),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Progress Manifesto';
                      widget.onManifestoTitleChange('Ward $wardId Progress Manifesto');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Ward $wardId Citizen Welfare Plan'),
                    subtitle: const Text('Focus on citizen welfare'),
                    onTap: () {
                      _titleController.text = 'Ward $wardId Citizen Welfare Plan';
                      widget.onManifestoTitleChange('Ward $wardId Citizen Welfare Plan');
                      Navigator.of(context).pop();
                    },
                  ),
                ]

                // Marathi Titles
                else ...[
                  ListTile(
                    title: Text('वॉर्ड $wardId विकास योजना'),
                    subtitle: const Text('मानक विकास केंद्रित'),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId विकास योजना';
                      widget.onManifestoTitleChange('वॉर्ड $wardId विकास योजना');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId विकास आणि पारदर्शकता योजना'),
                    subtitle: const Text('पारदर्शकतेसह विकास'),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId विकास आणि पारदर्शकता योजना';
                      widget.onManifestoTitleChange('वॉर्ड $wardId विकास आणि पारदर्शकता योजना');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId प्रगती घोषणापत्र'),
                    subtitle: const Text('प्रगती आणि वाढ केंद्रित'),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId प्रगती घोषणापत्र';
                      widget.onManifestoTitleChange('वॉर्ड $wardId प्रगती घोषणापत्र');
                      Navigator.of(context).pop();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('वॉर्ड $wardId नागरिक कल्याण योजना'),
                    subtitle: const Text('नागरिक कल्याण केंद्रित'),
                    onTap: () {
                      _titleController.text = 'वॉर्ड $wardId नागरिक कल्याण योजना';
                      widget.onManifestoTitleChange('वॉर्ड $wardId नागरिक कल्याण योजना');
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
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoTemplatesForPromise(int index) {
    String selectedLanguage = 'en'; // Default to English

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Choose Demo Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Language Selection
                const Text(
                  'Select Language:',
                  style: TextStyle(
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
                const Text(
                  'Choose Template:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Infrastructure & Cleanliness
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedLanguage == 'en' ? 'Infrastructure & Cleanliness' : 'पायाभूत सुविधा आणि स्वच्छता',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedLanguage == 'en' ? 'Clean water, roads & waste management' : 'स्वच्छ पाणी, रस्ते आणि कचरा व्यवस्थापन',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'स्वच्छ पाणी व चांगले रस्ते',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Use the specific demo format requested
                            debugPrint('Using Infrastructure & Cleanliness template for promise $index');
                            setState(() {
                              // Update controllers
                              final titleController = _promiseControllers[index]['title'] as TextEditingController? ?? TextEditingController();
                              titleController.text = 'स्वच्छ पाणी व चांगले रस्ते'; // Clean text without ** markers
                              _promiseControllers[index]['title'] = titleController;

                              // Clear existing points and add new ones
                              final pointsList = <TextEditingController>[
                                TextEditingController(text: 'प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.'),
                                TextEditingController(text: 'खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.'),
                              ];
                              _promiseControllers[index]['points'] = pointsList;

                              // Update manifesto data
                              final updatedPromises = _promiseControllers.map((controller) {
                                final title = (controller['title'] as TextEditingController).text;
                                final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                return <String, dynamic>{'title': title, 'points': points};
                              }).toList();
                              widget.onManifestoPromisesChange(updatedPromises);
                            });
                            debugPrint('Template applied successfully to promise $index');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Use This Template'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                const SizedBox(height: 12),
                // Transparency & Accountability
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedLanguage == 'en' ? 'Transparency & Accountability' : 'पारदर्शकता आणि जबाबदारी',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedLanguage == 'en' ? 'Open governance & citizen participation' : 'खुलं शासन आणि नागरिक सहभाग',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'पारदर्शकता आणि जबाबदारी',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• नियमित सार्वजनिक बैठक आणि अद्यतने',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• खुला बजेट चर्चा',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Use transparency demo format
                            debugPrint('Using Transparency & Accountability template for promise $index');
                            setState(() {
                              // Update controllers
                              final titleController = _promiseControllers[index]['title'] as TextEditingController? ?? TextEditingController();
                              titleController.text = 'पारदर्शकता आणि जबाबदारी'; // Clean text without ** markers
                              _promiseControllers[index]['title'] = titleController;

                              // Clear existing points and add new ones
                              final pointsList = <TextEditingController>[
                                TextEditingController(text: 'नियमित सार्वजनिक बैठक आणि अद्यतने'),
                                TextEditingController(text: 'खुला बजेट चर्चा'),
                              ];
                              _promiseControllers[index]['points'] = pointsList;

                              // Update manifesto data
                              final updatedPromises = _promiseControllers.map((controller) {
                                final title = (controller['title'] as TextEditingController).text;
                                final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                return <String, dynamic>{'title': title, 'points': points};
                              }).toList();
                              widget.onManifestoPromisesChange(updatedPromises);
                            });
                            debugPrint('Template applied successfully to promise $index');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Use This Template'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                const SizedBox(height: 12),
                // Education & Youth Development
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedLanguage == 'en' ? 'Education & Youth Development' : 'शिक्षण आणि युवा विकास',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedLanguage == 'en' ? 'Digital education & skill training' : 'डिजिटल शिक्षण आणि कौशल्य प्रशिक्षण',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'शिक्षण आणि युवा विकास',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• कौशल्य प्रशिक्षण कार्यक्रम',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Use youth education demo format
                            debugPrint('Using Education & Youth Development template for promise $index');
                            setState(() {
                              // Update controllers
                              final titleController = _promiseControllers[index]['title'] as TextEditingController? ?? TextEditingController();
                              titleController.text = 'शिक्षण आणि युवा विकास'; // Clean text without ** markers
                              _promiseControllers[index]['title'] = titleController;

                              // Clear existing points and add new ones
                              final pointsList = <TextEditingController>[
                                TextEditingController(text: 'डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र'),
                                TextEditingController(text: 'कौशल्य प्रशिक्षण कार्यक्रम'),
                              ];
                              _promiseControllers[index]['points'] = pointsList;

                              // Update manifesto data
                              final updatedPromises = _promiseControllers.map((controller) {
                                final title = (controller['title'] as TextEditingController).text;
                                final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                return <String, dynamic>{'title': title, 'points': points};
                              }).toList();
                              widget.onManifestoPromisesChange(updatedPromises);
                            });
                            debugPrint('Template applied successfully to promise $index');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Use This Template'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                const SizedBox(height: 12),
                // Women & Safety Measures
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedLanguage == 'en' ? 'Women & Safety Measures' : 'महिला आणि सुरक्षा उपाय',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedLanguage == 'en' ? 'Women empowerment & security' : 'महिला सशक्तीकरण आणि सुरक्षा',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'महिला आणि सुरक्षा',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• महिलांसाठी विशेष आरोग्य केंद्र',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '• प्रत्येक चौकात CCTV कॅमेरे',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Use women safety demo format
                            debugPrint('Using Women & Safety Measures template for promise $index');
                            setState(() {
                              // Update controllers
                              final titleController = _promiseControllers[index]['title'] as TextEditingController? ?? TextEditingController();
                              titleController.text = 'महिला आणि सुरक्षा'; // Clean text without ** markers
                              _promiseControllers[index]['title'] = titleController;

                              // Clear existing points and add new ones
                              final pointsList = <TextEditingController>[
                                TextEditingController(text: 'महिलांसाठी विशेष आरोग्य केंद्र'),
                                TextEditingController(text: 'प्रत्येक चौकात CCTV कॅमेरे'),
                              ];
                              _promiseControllers[index]['points'] = pointsList;

                              // Update manifesto data
                              final updatedPromises = _promiseControllers.map((controller) {
                                final title = (controller['title'] as TextEditingController).text;
                                final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                return <String, dynamic>{'title': title, 'points': points};
                              }).toList();
                              widget.onManifestoPromisesChange(updatedPromises);
                            });
                            debugPrint('Template applied successfully to promise $index');
                            Navigator.of(context).pop();
                          },
                          child: const Text('Use This Template'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadManifestoPdf() async {
    debugPrint('📄 [PDF Upload] Starting PDF selection process...');

    setState(() {
      _isUploadingPdf = true;
    });

    try {
      // Step 1: Pick file from device
      debugPrint('📄 [PDF Upload] Step 1: Picking file from device...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('📄 [PDF Upload] User cancelled file selection');
        setState(() {
          _isUploadingPdf = false;
        });
        return;
      }

      final file = result.files.first;
      final fileSize = file.size;
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint('📄 [PDF Upload] File selected: ${file.name}, Size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Step 2: Validate file size locally
      debugPrint('📄 [PDF Upload] Step 2: Validating file size...');
      if (fileSizeMB > 20.0) {
        debugPrint('📄 [PDF Upload] File too large: ${fileSizeMB.toStringAsFixed(1)}MB > 20MB limit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isUploadingPdf = false;
        });
        return;
      }

      debugPrint('📄 [PDF Upload] File size validation passed');

      // Step 3: Save to local storage and show to user
      debugPrint('📄 [PDF Upload] Step 3: Saving to local storage...');
      final localPath = await _saveFileLocally(file, 'pdf');
      if (localPath == null) {
        debugPrint('📄 [PDF Upload] Failed to save locally');
        throw Exception('Failed to save file locally');
      }
      debugPrint('📄 [PDF Upload] Saved locally at: $localPath');

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'pdf',
          'localPath': localPath,
          'fileName': file.name,
          'fileSize': fileSizeMB,
        });
      });

      debugPrint('📄 [PDF Upload] PDF saved locally and added to display list');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF selected and ready for upload. Press Save to upload to server.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('📄 [PDF Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPdf = false;
      });
      debugPrint('📄 [PDF Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoImage() async {
    debugPrint('🖼️ [Image Upload] Starting image selection process...');

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Step 1: Pick image from gallery
      debugPrint('🖼️ [Image Upload] Step 1: Picking image from gallery...');
      final ImagePicker imagePicker = ImagePicker();
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('🖼️ [Image Upload] User cancelled image selection');
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      debugPrint('🖼️ [Image Upload] Image selected: ${image.name}, Path: ${image.path}');

      // Step 2: Optimize image for manifesto (higher quality than achievements)
      debugPrint('🖼️ [Image Upload] Step 2: Optimizing image for manifesto...');
      final optimizedImage = await _optimizeManifestoImage(image);
      debugPrint('🖼️ [Image Upload] Image optimization completed');

      // Step 3: Validate file size with optimized image
      debugPrint('🖼️ [Image Upload] Step 3: Validating optimized file size...');
      final validation = await _validateManifestoFileSize(optimizedImage.path, 'image');

      if (!validation.isValid) {
        debugPrint('🖼️ [Image Upload] File too large after optimization');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Show warning for large files
      if (validation.warning) {
        final proceed = await _showFileSizeWarningDialog(validation);
        if (proceed != true) {
          debugPrint('🖼️ [Image Upload] User cancelled after size warning');
          setState(() {
            _isUploadingImage = false;
          });
          return;
        }
      }

      debugPrint('🖼️ [Image Upload] File size validation passed');

      // Step 4: Save optimized image to local storage
      debugPrint('🖼️ [Image Upload] Step 4: Saving optimized image to local storage...');
      final localPath = await _saveFileLocally(optimizedImage, 'image');
      if (localPath == null) {
        debugPrint('🖼️ [Image Upload] Failed to save locally');
        throw Exception('Failed to save optimized image locally');
      }
      debugPrint('🖼️ [Image Upload] Saved locally at: $localPath');

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'image',
          'localPath': localPath,
          'fileName': optimizedImage.name,
          'fileSize': validation.fileSizeMB,
        });
      });

      debugPrint('🖼️ [Image Upload] Optimized image saved locally and added to display list');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image optimized and ready for upload (${validation.fileSizeMB.toStringAsFixed(1)}MB). Press Save to upload to server.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      debugPrint('🖼️ [Image Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
      debugPrint('🖼️ [Image Upload] Selection process completed');
    }
  }

  Future<void> _uploadManifestoVideo() async {
    debugPrint('🎥 [Video Upload] Starting premium video selection process...');

    if (!widget.candidateData.premium) {
      debugPrint('🎥 [Video Upload] User is not premium, showing premium message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video upload is a premium feature. Upgrade to upload videos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      debugPrint('🎥 [Video Upload] Step 1: Picking video from gallery...');
      final ImagePicker videoPicker = ImagePicker();
      final XFile? video = await videoPicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // Extended to 10 minutes for premium
      );

      if (video == null) {
        debugPrint('🎥 [Video Upload] User cancelled video selection');
        setState(() {
          _isUploadingVideo = false;
        });
        return;
      }

      debugPrint('🎥 [Video Upload] Video selected: ${video.name}, Path: ${video.path}');

      // Step 2: Validate file size locally
      debugPrint('🎥 [Video Upload] Step 2: Validating file size...');
      final file = File(video.path);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint('🎥 [Video Upload] File size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Validate file size (max 500MB for premium videos)
      if (fileSizeMB > 500.0) {
        debugPrint('🎥 [Video Upload] File too large: ${fileSizeMB.toStringAsFixed(1)}MB > 500MB limit');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 500MB for premium users.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
        setState(() {
          _isUploadingVideo = false;
        });
        return;
      }

      // Show processing info for large files
      if (fileSizeMB > 100.0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium video detected (${fileSizeMB.toStringAsFixed(0)}MB). Will be processed with multi-resolution optimization for fast loading.'),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      debugPrint('🎥 [Video Upload] File size validation passed');

      // Step 3: Save to local storage and show to user
      debugPrint('🎥 [Video Upload] Step 3: Saving to local storage...');
      final localPath = await _saveFileLocally(video, 'video');
      if (localPath == null) {
        debugPrint('🎥 [Video Upload] Failed to save locally');
        throw Exception('Failed to save video locally');
      }
      debugPrint('🎥 [Video Upload] Saved locally at: $localPath');

      // Add to local files list for visual display
      setState(() {
        _localFiles.add({
          'type': 'video',
          'localPath': localPath,
          'fileName': video.name,
          'fileSize': fileSizeMB,
          'isPremium': true, // Mark as premium video
        });
      });

      debugPrint('🎥 [Video Upload] Premium video saved locally and added to display list');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium video selected and ready for processing. Press Save to upload and optimize for thousands of voters.'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('🎥 [Video Upload] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingVideo = false;
      });
      debugPrint('🎥 [Video Upload] Selection process completed');
    }
  }

  // Local storage helper methods
  Future<String?> _saveFileLocally(dynamic file, String type) async {
    try {
      debugPrint('💾 [Local Storage] Saving $type file locally...');

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final localDir = Directory('${directory.path}/manifesto_temp');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
        debugPrint('💾 [Local Storage] Created temp directory: ${localDir.path}');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = widget.candidateData.userId ?? 'unknown_user';
      final fileName = 'temp_${type}_${userId}_$timestamp.${type == 'pdf' ? 'pdf' : 'tmp'}';
      final localPath = '${localDir.path}/$fileName';

      // Save file locally
      if (file is PlatformFile) {
        if (file.bytes != null) {
          // Web platform
          final localFile = File(localPath);
          await localFile.writeAsBytes(file.bytes!);
          debugPrint('💾 [Local Storage] Saved web file to: $localPath');
        } else if (file.path != null) {
          // Mobile platform
          await File(file.path!).copy(localPath);
          debugPrint('💾 [Local Storage] Copied mobile file to: $localPath');
        }
      } else if (file is XFile) {
        // Image picker file
        await File(file.path).copy(localPath);
        debugPrint('💾 [Local Storage] Copied image file to: $localPath');
      }

      debugPrint('💾 [Local Storage] File saved successfully at: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('💾 [Local Storage] Error saving file locally: $e');
      return null;
    }
  }

  Future<void> _cleanupLocalFile(String localPath) async {
    try {
      debugPrint('🧹 [Local Storage] Cleaning up local file: $localPath');
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🧹 [Local Storage] Local file deleted successfully');
      } else {
        debugPrint('🧹 [Local Storage] Local file not found, nothing to clean');
      }
    } catch (e) {
      debugPrint('🧹 [Local Storage] Error cleaning up local file: $e');
    }
  }

  // Enhanced upload method with Cloudinary integration for videos
  Future<void> _uploadLocalFilesToFirebase() async {
    debugPrint('☁️ [Enhanced Upload] Starting upload for ${_localFiles.length} local files...');

    for (final localFile in _localFiles) {
      try {
        final type = localFile['type'] as String;
        final localPath = localFile['localPath'] as String;
        final fileName = localFile['fileName'] as String;
        final isPremiumVideo = localFile['isPremium'] as bool? ?? false;

        debugPrint('☁️ [Enhanced Upload] Processing $type file: $fileName (Premium: $isPremiumVideo)');

        final file = File(localPath);

        // Handle video uploads with Cloudinary for premium users
        if (type == 'video' && isPremiumVideo) {
          debugPrint('🎥 [Cloudinary Upload] Processing premium video with Cloudinary...');

          try {
            // Initialize VideoProcessingService
            final videoService = VideoProcessingService();

            // Show processing progress
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Processing premium video with multi-resolution optimization...'),
                backgroundColor: Colors.purple,
                duration: Duration(seconds: 3),
              ),
            );

            // Upload and process video through Cloudinary
            final processedVideo = await videoService.uploadAndProcessVideo(
              file,
              widget.candidateData.userId ?? 'unknown_user',
              onProgress: (progress) {
                debugPrint('🎥 [Cloudinary Progress] ${progress.toStringAsFixed(1)}%');
              },
            );

            debugPrint('🎥 [Cloudinary Success] Video processed successfully: ${processedVideo.id}');

            // Update candidate with processed video URL
            widget.onManifestoVideoChange(processedVideo.originalUrl);

            // Clean up local file
            await _cleanupLocalFile(localPath);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Premium video processed and optimized! Available in ${processedVideo.resolutions.length} resolutions.'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );

          } catch (cloudinaryError) {
            debugPrint('🎥 [Cloudinary Error] $cloudinaryError');

            // Fallback to Firebase Storage for videos if Cloudinary fails
            debugPrint('🎥 [Fallback] Using Firebase Storage as fallback...');
            await _uploadVideoToFirebase(file, localPath, fileName);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video uploaded successfully (basic processing)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // Handle regular files (PDF, Image, non-premium video) with Firebase
          await _uploadRegularFileToFirebase(file, localPath, fileName, type);
        }

      } catch (e) {
        debugPrint('☁️ [Enhanced Upload] Error processing ${localFile['type']}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${localFile['type']}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Clear local files list after upload
    setState(() {
      _localFiles.clear();
    });

    debugPrint('☁️ [Enhanced Upload] All local files processed');
  }

  // Upload regular files (PDF, Image, non-premium video) to Firebase
  Future<void> _uploadRegularFileToFirebase(File file, String localPath, String fileName, String type) async {
    debugPrint('📄 [Firebase Upload] Uploading regular $type file: $fileName');

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    // Generate unique filename for Firebase
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = widget.candidateData.userId ?? 'unknown_user';
    final firebaseFileName = '${type}_${userId}_${timestamp}.${_getFileExtension(type)}';

    // Determine storage path based on file type
    String storagePath;
    switch (type) {
      case 'pdf':
        storagePath = 'manifestos/$firebaseFileName';
        break;
      case 'image':
        storagePath = 'manifesto_images/$firebaseFileName';
        break;
      case 'video':
        storagePath = 'manifesto_videos/$firebaseFileName';
        break;
      default:
        debugPrint('📄 [Firebase Upload] Unknown file type: $type');
        return;
    }

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Upload file
    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: _getContentType(type)),
    );

    // Monitor upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      debugPrint('📄 [Firebase Upload] $type upload progress: ${progress.toStringAsFixed(1)}%');
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    debugPrint('📄 [Firebase Upload] $type uploaded successfully. URL: $downloadUrl');

    // Update candidate data based on file type
    if (type == 'pdf') {
      widget.onManifestoPdfChange(downloadUrl);
    } else if (type == 'image') {
      widget.onManifestoImageChange(downloadUrl);
    } else if (type == 'video') {
      widget.onManifestoVideoChange(downloadUrl);
    }

    // Clean up local file after successful upload
    await _cleanupLocalFile(localPath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type uploaded successfully (${fileSizeMB.toStringAsFixed(1)}MB)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Fallback method for video upload to Firebase (when Cloudinary fails)
  Future<void> _uploadVideoToFirebase(File file, String localPath, String fileName) async {
    debugPrint('🎥 [Firebase Fallback] Uploading video to Firebase Storage...');

    final fileSize = await file.length();
    final fileSizeMB = fileSize / (1024 * 1024);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = widget.candidateData.userId ?? 'unknown_user';
    final firebaseFileName = 'video_${userId}_${timestamp}.mp4';
    final storagePath = 'manifesto_videos/$firebaseFileName';

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      debugPrint('🎥 [Firebase Fallback] Upload progress: ${progress.toStringAsFixed(1)}%');
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    debugPrint('🎥 [Firebase Fallback] Video uploaded successfully. URL: $downloadUrl');

    // Update candidate with video URL
    widget.onManifestoVideoChange(downloadUrl);

    // Clean up local file
    await _cleanupLocalFile(localPath);
  }

  // Helper methods
  String _getFileExtension(String type) {
    switch (type) {
      case 'pdf':
        return 'pdf';
      case 'image':
        return 'jpg';
      case 'video':
        return 'mp4';
      default:
        return 'tmp';
    }
  }

  String _getContentType(String type) {
    switch (type) {
      case 'pdf':
        return 'application/pdf';
      case 'image':
        return 'image/jpeg';
      case 'video':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  // Method to be called when save button is pressed
  Future<void> uploadPendingFiles() async {
    if (_localFiles.isNotEmpty) {
      debugPrint('💾 [Save] Uploading ${_localFiles.length} pending local files to Firebase...');
      await _uploadLocalFilesToFirebase();
    } else {
      debugPrint('💾 [Save] No pending local files to upload');
    }
  }

  // File size validation for manifesto files
  Future<FileSizeValidation> _validateManifestoFileSize(String filePath, String type) async {
    try {
      final file = File(filePath.replaceFirst('local:', ''));
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      switch (type) {
        case 'pdf':
          if (fileSizeMB > 20.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message: 'PDF file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 20MB.',
              recommendation: 'Please choose a smaller PDF or compress the current one.',
            );
          } else if (fileSizeMB > 10.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message: 'Large PDF detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation: 'Consider compressing the PDF for faster uploads.',
              warning: true,
            );
          }
          break;

        case 'image':
          if (fileSizeMB > 10.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message: 'Image file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 10MB.',
              recommendation: 'Please choose a smaller image or compress the current one.',
            );
          } else if (fileSizeMB > 5.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message: 'Large image detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation: 'Consider compressing the image for faster uploads.',
              warning: true,
            );
          }
          break;

        case 'video':
          if (fileSizeMB > 100.0) {
            return FileSizeValidation(
              isValid: false,
              fileSizeMB: fileSizeMB,
              message: 'Video file is too large (${fileSizeMB.toStringAsFixed(1)}MB). Maximum allowed is 100MB.',
              recommendation: 'Please choose a smaller video or compress the current one.',
            );
          } else if (fileSizeMB > 50.0) {
            return FileSizeValidation(
              isValid: true,
              fileSizeMB: fileSizeMB,
              message: 'Large video detected (${fileSizeMB.toStringAsFixed(1)}MB). Upload may take longer.',
              recommendation: 'Consider compressing the video for faster uploads.',
              warning: true,
            );
          }
          break;
      }

      return FileSizeValidation(
        isValid: true,
        fileSizeMB: fileSizeMB,
        message: 'File size is acceptable (${fileSizeMB.toStringAsFixed(1)}MB).',
        recommendation: null,
      );
    } catch (e) {
      return FileSizeValidation(
        isValid: false,
        fileSizeMB: 0,
        message: 'Unable to validate file size: $e',
        recommendation: 'Please try again or choose a different file.',
      );
    }
  }

  // Show file size warning dialog
  Future<bool?> _showFileSizeWarningDialog(FileSizeValidation validation) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Size Warning'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.message),
            if (validation.recommendation != null) ...[
              const SizedBox(height: 8),
              Text(
                validation.recommendation!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'File size: ${validation.fileSizeMB.toStringAsFixed(1)}MB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose Different File'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }



  // Optimize image for manifesto (higher quality than achievements)
  Future<XFile> _optimizeManifestoImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1024 * 1024);

      debugPrint('🖼️ [Manifesto Image] Original size: ${fileSizeMB.toStringAsFixed(2)} MB');

      // Manifesto images need higher quality than achievement photos
      int quality = 85; // Higher than achievements (80)
      int? maxWidth;
      int? maxHeight;

      if (fileSizeMB > 8.0) {
        // Very large files (>8MB) - moderate optimization for manifesto
        quality = 75;
        maxWidth = 1600;
        maxHeight = 1600;
        debugPrint('🖼️ [Manifesto Image] Large file detected (>8MB), applying moderate optimization');
      } else if (fileSizeMB > 4.0) {
        // Large files (4-8MB) - light optimization
        quality = 80;
        maxWidth = 2000;
        maxHeight = 2000;
        debugPrint('🖼️ [Manifesto Image] Large file detected (4-8MB), applying light optimization');
      } else {
        // Small files - no optimization needed
        debugPrint('🖼️ [Manifesto Image] File size acceptable, no optimization needed');
        return image;
      }

      // Create optimized version
      final ImagePicker imagePicker = ImagePicker();
      final optimizedImage = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: quality,
      );

      if (optimizedImage != null) {
        final optimizedFile = File(optimizedImage.path);
        final optimizedSize = await optimizedFile.length();
        final optimizedSizeMB = optimizedSize / (1024 * 1024);

        debugPrint('🖼️ [Manifesto Image] Optimized size: ${optimizedSizeMB.toStringAsFixed(2)} MB (${((fileSize - optimizedSize) / fileSize * 100).toStringAsFixed(1)}% reduction)');
        return optimizedImage;
      }

      // If optimization failed, return original
      return image;

    } catch (e) {
      debugPrint('⚠️ [Manifesto Image] Optimization failed, using original: $e');
      return image;
    }
  }

  Widget _buildAnalyticsItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.editedData ?? widget.candidateData;
    final manifesto = data.extraInfo?.manifesto?.title ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manifesto Title
            if (widget.isEditing) ...[
              const Text(
                'Manifesto Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Manifesto Title',
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Ward 23 Development & Transparency Plan',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.lightbulb, color: Colors.amber),
                    onPressed: _showDemoTitleOptions,
                    tooltip: 'Use demo title',
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (v) => widget.onManifestoTitleChange(v),
              ),
              const SizedBox(height: 16),
            ] else if (data.extraInfo?.manifesto?.title != null && data.extraInfo!.manifesto!.title!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _stripBoldMarkers(data.extraInfo!.manifesto!.title!),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Manifesto Promises (Dynamic Add/Delete)
            if (widget.isEditing) ...[
              const Text(
                'Key Promises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_promiseControllers.length, (index) {
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
                                    icon: const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                                    onPressed: () => _showDemoTemplatesForPromise(index),
                                    tooltip: 'Use demo template',
                                  ),
                                  if (_promiseControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _promiseControllers.removeAt(index);
                                        });
                                        // Create updated promises list from controllers
                                        final updatedPromises = _promiseControllers.map((controller) {
                                          final title = (controller['title'] as TextEditingController).text;
                                          final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                          return <String, dynamic>{'title': title, 'points': points};
                                        }).toList();
                                        widget.onManifestoPromisesChange(updatedPromises);
                                        debugPrint('Deleted promise at index $index, remaining promises: ${_promiseControllers.length}');
                                      },
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
                                  controller: _promiseControllers[index]['title'] as TextEditingController? ?? TextEditingController(),
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
                                  onChanged: (value) {
                                    // Update the promise data through callback
                                    final updatedPromises = _promiseControllers.map((controller) {
                                      final title = (controller['title'] as TextEditingController).text;
                                      final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                      return <String, dynamic>{'title': title, 'points': points};
                                    }).toList();
                                    widget.onManifestoPromisesChange(updatedPromises);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Promise Points
                              ...List.generate(((_promiseControllers[index]['points'] as List<TextEditingController>?) ?? []).length, (pointIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8, left: 24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: ((_promiseControllers[index]['points'] as List<TextEditingController>?) ?? [])[pointIndex],
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
                                            hintText: pointIndex == 0 ? 'Provide 24x7 clean water to every household' : 'Pothole-free ward roads in 1 year',
                                            hintStyle: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          onChanged: (value) {
                                            // Update the promise data through callback
                                            final updatedPromises = _promiseControllers.map((controller) {
                                              final title = (controller['title'] as TextEditingController).text;
                                              final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                              return <String, dynamic>{'title': title, 'points': points};
                                            }).toList();
                                            widget.onManifestoPromisesChange(updatedPromises);
                                          },
                                        ),
                                      ),
                                      if (((_promiseControllers[index]['points'] as List<TextEditingController>?) ?? []).length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () {
                                            final pointsList = _promiseControllers[index]['points'] as List<TextEditingController>? ?? [];

                                            setState(() {
                                              pointsList.removeAt(pointIndex);
                                              _promiseControllers[index]['points'] = pointsList;
                                            });

                                            // Update the promise data through callback
                                            final updatedPromises = _promiseControllers.map((controller) {
                                              final title = (controller['title'] as TextEditingController).text;
                                              final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                              return <String, dynamic>{'title': title, 'points': points};
                                            }).toList();
                                            widget.onManifestoPromisesChange(updatedPromises);
                                          },
                                          tooltip: 'Delete Point',
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              // Add Point Button
                              Padding(
                                padding: const EdgeInsets.only(left: 16, top: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      debugPrint('Add Point button pressed for promise $index');
                                      final pointsList = _promiseControllers[index]['points'] as List<TextEditingController>? ?? [];

                                      setState(() {
                                        pointsList.add(TextEditingController());
                                        _promiseControllers[index]['points'] = pointsList;
                                      });

                                      // Update the promise data through callback
                                      final updatedPromises = _promiseControllers.map((controller) {
                                        final title = (controller['title'] as TextEditingController).text;
                                        final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                                        return <String, dynamic>{'title': title, 'points': points};
                                      }).toList();
                                      widget.onManifestoPromisesChange(updatedPromises);
                                      debugPrint('Added point to promise $index, total points: ${pointsList.length}');
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Point'),
                                    style: TextButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                  onPressed: () {
                    debugPrint('Add New Promise button pressed');
                    setState(() {
                      final newController = <String, dynamic>{
                        'title': TextEditingController(),
                        'points': <TextEditingController>[TextEditingController()],
                      };
                      _promiseControllers.add(newController);
                    });
                    // Create updated promises list from controllers
                    final updatedPromises = _promiseControllers.map((controller) {
                      final title = (controller['title'] as TextEditingController).text;
                      final points = (controller['points'] as List<TextEditingController>).map((c) => c.text).toList();
                      return <String, dynamic>{'title': title, 'points': points};
                    }).toList();
                    widget.onManifestoPromisesChange(updatedPromises);
                    debugPrint('Added new promise, total promises: ${_promiseControllers.length}');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Promise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else if (data.extraInfo?.manifesto?.promises != null && data.extraInfo!.manifesto!.promises!.isNotEmpty) ...[
              const Text(
                'Key Promises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(data.extraInfo!.manifesto!.promises!.length, (index) {
                final promise = data.extraInfo!.manifesto!.promises![index];
                if (promise.isEmpty) return const SizedBox.shrink();

                // Handle new structured format
                if (promise is Map<String, dynamic>) {
                  final title = promise['title'] as String? ?? '';
                  final points = promise['points'] as List<dynamic>? ?? [];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Promise Title
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            _stripBoldMarkers(title),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Promise Points
                        ...points.map((point) {
                          final pointIndex = points.indexOf(point) + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4, left: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$pointIndex',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _stripBoldMarkers(point.toString()),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  );
                } else {
                  // Fallback for old string format
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _stripBoldMarkers(promise.toString()),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              }),
            ],

            const SizedBox(height: 16),

            // Upload Buttons with Size Limits
            if (widget.isEditing) ...[
              const Text(
                'Upload Files',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  // PDF Upload Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload PDF',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'File must be < 20 MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: !_isUploadingPdf ? _uploadManifestoPdf : null,
                          icon: _isUploadingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: const Text('Choose PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Image Upload Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.image, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload Image',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'File must be < 10 MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: !_isUploadingImage ? _uploadManifestoImage : null,
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.photo_camera),
                          label: const Text('Choose Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Video Upload Row (Premium)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.candidateData.premium ? Colors.purple.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.candidateData.premium ? Colors.purple.shade200 : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.candidateData.premium ? Icons.video_call : Icons.lock,
                          color: widget.candidateData.premium ? Colors.purple.shade700 : Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.candidateData.premium ? 'Upload Video' : 'Premium Video',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: widget.candidateData.premium ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                widget.candidateData.premium ? 'File must be < 100 MB' : 'Premium feature required',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.candidateData.premium ? Colors.purple.shade600 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.candidateData.premium)
                          ElevatedButton.icon(
                            onPressed: !_isUploadingVideo ? _uploadManifestoVideo : null,
                            icon: _isUploadingVideo
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.videocam),
                            label: const Text('Choose Video'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade600,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Video upload is a premium feature'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.lock),
                            label: const Text('Premium'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.purple),
                              foregroundColor: Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Display locally stored files (ready for upload)
              if (_localFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pending, color: Colors.amber.shade700, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Files Ready for Upload (${_localFiles.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'These files will be uploaded to the server when you press Save.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._localFiles.map((localFile) {
                        final type = localFile['type'] as String;
                        final fileName = localFile['fileName'] as String;
                        final fileSize = localFile['fileSize'] as double;
                        final localPath = localFile['localPath'] as String;

                        IconData icon;
                        Color color;
                        switch (type) {
                          case 'pdf':
                            icon = Icons.picture_as_pdf;
                            color = Colors.red;
                            break;
                          case 'image':
                            icon = Icons.image;
                            color = Colors.green;
                            break;
                          case 'video':
                            icon = Icons.video_call;
                            color = Colors.purple;
                            break;
                          default:
                            icon = Icons.file_present;
                            color = Colors.grey;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${fileSize.toStringAsFixed(2)} MB • Ready for upload',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _localFiles.remove(localFile);
                                    });
                                    // Clean up the local file
                                    _cleanupLocalFile(localPath);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$fileName removed from upload queue'),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  },
                                  tooltip: 'Remove from upload queue',
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ],

            // Display uploaded files
            if (!widget.isEditing) ...[
              if (data.extraInfo?.manifesto?.pdfUrl != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manifesto PDF',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const Text(
                              'Tap to view your manifesto document',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          debugPrint('📄 [PDF Viewer] Opening PDF viewer for: ${data.extraInfo!.manifesto!.pdfUrl}');
                          // TODO: Implement PDF viewer
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF viewer will be implemented soon'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open PDF',
                      ),
                    ],
                  ),
                ),
              ],
              if (data.extraInfo?.manifesto?.images != null && data.extraInfo!.manifesto!.images!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.image, color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Manifesto Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AspectRatioImage(
                        imageUrl: data.extraInfo!.manifesto!.images!.first,
                        fit: BoxFit.contain,
                        minHeight: 120,
                        maxHeight: 250,
                        borderColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap image to view in full screen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              if (data.extraInfo?.manifesto?.videoUrl != null && data.extraInfo!.manifesto!.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.video_call, color: Colors.purple.shade700, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Manifesto Video',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: 16 / 9, // Maintain aspect ratio for video
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.black,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 64,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Premium Video',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Premium video content available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Analytics Section (for premium users)
            if (!widget.isEditing && widget.candidateData.premium && data.extraInfo?.analytics != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Manifesto Analytics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAnalyticsItem(
                          icon: Icons.visibility,
                          label: 'Views',
                          value: '${data.extraInfo!.analytics!.profileViews ?? 0}',
                          color: Colors.blue,
                        ),
                        _buildAnalyticsItem(
                          icon: Icons.thumb_up,
                          label: 'Likes',
                          value: '${data.extraInfo!.analytics!.engagementRate ?? 0}',
                          color: Colors.green,
                        ),
                        _buildAnalyticsItem(
                          icon: Icons.share,
                          label: 'Shares',
                          value: '${data.extraInfo!.analytics!.manifestoViews ?? 0}',
                          color: Colors.orange,
                        ),
                        _buildAnalyticsItem(
                          icon: Icons.download,
                          label: 'Downloads',
                          value: '0', // No downloads field in AnalyticsData
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
