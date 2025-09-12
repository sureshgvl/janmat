import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../../models/candidate_model.dart';
import '../../services/file_upload_service.dart';

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
  State<ManifestoSection> createState() => _ManifestoSectionState();
}

class _ManifestoSectionState extends State<ManifestoSection> {
  final GoogleTranslator _translator = GoogleTranslator();
  final FileUploadService _fileUploadService = FileUploadService();
  late TextEditingController _manifestoController;
  late TextEditingController _titleController;
  late List<Map<String, Object?>> _promiseControllers;
  String _currentLanguage = 'en'; // 'en' for English, 'mr' for Marathi
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isUploadingPdf = false;
  bool _isUploadingImage = false;
  bool _isUploadingVideo = false;
  String? _originalText;
  String? _manifestoTitle;
  List<Map<String, dynamic>> _manifestoPromises = [];

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    _originalText = data.extraInfo?.manifesto?.title ?? '';
    _translatedText = _originalText ?? '';
    _manifestoController = TextEditingController(text: _originalText);

    // Initialize title
    _manifestoTitle = data.extraInfo?.manifesto?.title ?? '';
    _titleController = TextEditingController(text: _manifestoTitle);

    // Initialize manifesto promises list with structured format
    final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
    _manifestoPromises = rawPromises.map((promise) => {'title': promise, 'points': [promise]}).toList();

    // Initialize controllers for existing promises
    _promiseControllers = _manifestoPromises.map((promise) => <String, Object?>{
      'title': TextEditingController(text: promise['title'] ?? ''),
      'points': (promise['points'] as List<dynamic>? ?? []).map((point) =>
          TextEditingController(text: point.toString())).toList(),
    }).toList();

    // If no promises exist, create one empty promise
    if (_manifestoPromises.isEmpty) {
      _manifestoPromises.add({'title': '', 'points': ['']});
      _promiseControllers.add(<String, Object?>{
        'title': TextEditingController(),
        'points': [TextEditingController()],
      });
    }
  }

  @override
  void didUpdateWidget(ManifestoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final data = widget.editedData ?? widget.candidateData;
    final newText = data.extraInfo?.manifesto ?? '';
    if (_originalText != newText) {
      _originalText = newText as String?;
      _manifestoController.text = newText as String;
      if (_currentLanguage == 'en') {
        _translatedText = newText as String;
      } else {
        _translateText(newText as String, _currentLanguage);
      }
    }

    // Update title
    final newTitle = data.extraInfo?.manifesto?.title ?? '';
    if (_manifestoTitle != newTitle) {
      _manifestoTitle = newTitle;
      _titleController.text = newTitle;
    }

    // Update manifesto promises
    final rawPromises = data.extraInfo?.manifesto?.promises ?? [];
    final newManifestoPromises = rawPromises.map((promise) => {'title': promise, 'points': [promise]}).toList();
    if (_manifestoPromises != newManifestoPromises) {
      _manifestoPromises = List.from(newManifestoPromises);

      // Update controllers
      _promiseControllers = _manifestoPromises.map((promise) => <String, Object?>{
        'title': TextEditingController(text: promise['title'] ?? ''),
        'points': (promise['points'] as List<dynamic>? ?? []).map((point) =>
            TextEditingController(text: point.toString())).toList(),
      }).toList();

      // If no promises exist, create one empty promise
      if (_manifestoPromises.isEmpty) {
        _manifestoPromises.add({'title': '', 'points': ['']});
        _promiseControllers.add(<String, Object?>{
          'title': TextEditingController(),
          'points': [TextEditingController()],
        });
      }
    }
  }

  @override
  void dispose() {
    _manifestoController.dispose();
    _titleController.dispose();
    for (var controllerMap in _promiseControllers) {
      (controllerMap['title'] as TextEditingController).dispose();
      for (var pointController in (controllerMap['points'] as List<TextEditingController>)) {
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
    final cityId = widget.candidateData.cityId;
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
                            this.setState(() {
                              (_promiseControllers[index]['title'] as TextEditingController).text = 'स्वच्छ पाणी व चांगले रस्ते';
                              (_promiseControllers[index]['points'] as List<TextEditingController>).clear();
                              (_promiseControllers[index]['points'] as List<TextEditingController>).addAll([
                                TextEditingController(text: 'प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.'),
                                TextEditingController(text: 'खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.'),
                              ]);
                              _manifestoPromises[index] = {
                                'title': 'स्वच्छ पाणी व चांगले रस्ते',
                                'points': ['प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.', 'खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.']
                              };
                            });
                            widget.onManifestoPromisesChange(_manifestoPromises);
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
                            this.setState(() {
                              (_promiseControllers[index]['title'] as TextEditingController).text = 'पारदर्शकता आणि जबाबदारी';
                              (_promiseControllers[index]['points'] as List<TextEditingController>).clear();
                              (_promiseControllers[index]['points'] as List<TextEditingController>).addAll([
                                TextEditingController(text: 'नियमित सार्वजनिक बैठक आणि अद्यतने'),
                                TextEditingController(text: 'खुला बजेट चर्चा'),
                              ]);
                              _manifestoPromises[index] = {
                                'title': 'पारदर्शकता आणि जबाबदारी',
                                'points': ['नियमित सार्वजनिक बैठक आणि अद्यतने', 'खुला बजेट चर्चा']
                              };
                            });
                            widget.onManifestoPromisesChange(_manifestoPromises);
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
                            this.setState(() {
                              (_promiseControllers[index]['title'] as TextEditingController).text = 'शिक्षण आणि युवा विकास';
                              (_promiseControllers[index]['points'] as List<TextEditingController>).clear();
                              (_promiseControllers[index]['points'] as List<TextEditingController>).addAll([
                                TextEditingController(text: 'डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र'),
                                TextEditingController(text: 'कौशल्य प्रशिक्षण कार्यक्रम'),
                              ]);
                              _manifestoPromises[index] = {
                                'title': 'शिक्षण आणि युवा विकास',
                                'points': ['डिजिटल लायब्ररी आणि ई-लर्निंग केंद्र', 'कौशल्य प्रशिक्षण कार्यक्रम']
                              };
                            });
                            widget.onManifestoPromisesChange(_manifestoPromises);
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
                            this.setState(() {
                              (_promiseControllers[index]['title'] as TextEditingController).text = 'महिला आणि सुरक्षा';
                              (_promiseControllers[index]['points'] as List<TextEditingController>).clear();
                              (_promiseControllers[index]['points'] as List<TextEditingController>).addAll([
                                TextEditingController(text: 'महिलांसाठी विशेष आरोग्य केंद्र'),
                                TextEditingController(text: 'प्रत्येक चौकात CCTV कॅमेरे'),
                              ]);
                              _manifestoPromises[index] = {
                                'title': 'महिला आणि सुरक्षा',
                                'points': ['महिलांसाठी विशेष आरोग्य केंद्र', 'प्रत्येक चौकात CCTV कॅमेरे']
                              };
                            });
                            widget.onManifestoPromisesChange(_manifestoPromises);
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
    setState(() {
      _isUploadingPdf = true;
    });

    try {
      final pdfUrl = await _fileUploadService.uploadManifestoPdf(
        widget.candidateData.userId ?? 'unknown_user',
      );

      if (pdfUrl != null) {
        widget.onManifestoPdfChange(pdfUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manifesto PDF uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPdf = false;
      });
    }
  }

  Future<void> _uploadManifestoImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl = await _fileUploadService.uploadManifestoImage(
        widget.candidateData.userId ?? 'unknown_user',
      );

      if (imageUrl != null) {
        widget.onManifestoImageChange(imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manifesto image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _uploadManifestoVideo() async {
    if (!widget.candidateData.premium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video upload is a premium feature'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingVideo = true;
    });

    try {
      final videoUrl = await _fileUploadService.uploadManifestoVideo(
        widget.candidateData.userId ?? 'unknown_user',
      );

      if (videoUrl != null) {
        widget.onManifestoVideoChange(videoUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manifesto video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingVideo = false;
      });
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
    final manifesto = data.extraInfo?.manifesto ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Manifesto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Note: manifestoVerified property doesn't exist in the model
                    // Commenting out until model is updated
                    // if (data.extraInfo?.manifestoVerified == true) ...[
                    //   Container(...)
                    // ]
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!widget.isEditing && (manifesto as String?)?.isNotEmpty == true)
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _currentLanguage == 'en' ? null : () => _changeLanguage('en'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentLanguage == 'en'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor: _currentLanguage == 'en'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'English',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _currentLanguage == 'mr' ? null : () => _changeLanguage('mr'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentLanguage == 'mr'
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          foregroundColor: _currentLanguage == 'mr'
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text(
                          'मराठी',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

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
                  labelText: 'Title',
                  border: const OutlineInputBorder(),
                  hintText: 'e.g., Ward 23 Development & Transparency Plan',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.lightbulb, color: Colors.amber),
                    onPressed: _showDemoTitleOptions,
                    tooltip: 'Use demo title',
                  ),
                ),
                onChanged: widget.onManifestoTitleChange,
              ),
              const SizedBox(height: 16),
            ] else if (_manifestoTitle != null && _manifestoTitle!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _manifestoTitle!,
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
              ...List.generate(_manifestoPromises.length, (index) {
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
                                  if (_manifestoPromises.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _manifestoPromises.removeAt(index);
                                          _promiseControllers.removeAt(index);
                                        });
                                        widget.onManifestoPromisesChange(_manifestoPromises);
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
                                  controller: _promiseControllers[index]['title'] as TextEditingController,
                                  decoration: const InputDecoration(
                                    labelText: 'वचनाचा शीर्षक',
                                    border: OutlineInputBorder(),
                                    hintText: 'उदा. स्वच्छ पाणी व चांगले रस्ते',
                                  ),
                                  onChanged: (value) {
                                    _manifestoPromises[index]['title'] = value;
                                    widget.onManifestoPromisesChange(_manifestoPromises);
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Promise Points
                              ...List.generate((_promiseControllers[index]['points'] as List<TextEditingController>).length, (pointIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8, left: 24),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: (_promiseControllers[index]['points'] as List<TextEditingController>)[pointIndex],
                                          decoration: InputDecoration(
                                            labelText: 'बिंदू ${pointIndex + 1}',
                                            border: const OutlineInputBorder(),
                                            hintText: pointIndex == 0 ? 'प्रत्येक घराला २४x७ स्वच्छ पाणी पुरवठा.' : 'खड्डेमुक्त वॉर्ड रस्ते १ वर्षात.',
                                          ),
                                          onChanged: (value) {
                                            (_manifestoPromises[index]['points'] as List<dynamic>)[pointIndex] = value;
                                            widget.onManifestoPromisesChange(_manifestoPromises);
                                          },
                                        ),
                                      ),
                                      if ((_promiseControllers[index]['points'] as List<TextEditingController>).length > 1)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () {
                                            setState(() {
                                              (_promiseControllers[index]['points'] as List<TextEditingController>).removeAt(pointIndex);
                                              (_manifestoPromises[index]['points'] as List<dynamic>).removeAt(pointIndex);
                                            });
                                            widget.onManifestoPromisesChange(_manifestoPromises);
                                          },
                                          tooltip: 'Delete Point',
                                        ),
                                    ],
                                  ),
                                );
                              }),
                              // Add Point Button
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      (_promiseControllers[index]['points'] as List<TextEditingController>).add(TextEditingController());
                                      (_manifestoPromises[index]['points'] as List<dynamic>).add('');
                                    });
                                    widget.onManifestoPromisesChange(_manifestoPromises);
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('बिंदू जोडा'),
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
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _manifestoPromises.add({'title': '', 'points': ['']});
                      _promiseControllers.add(<String, Object?>{
                        'title': TextEditingController(),
                        'points': [TextEditingController()],
                      });
                    });
                    widget.onManifestoPromisesChange(_manifestoPromises);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Promise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else if (_manifestoPromises.isNotEmpty) ...[
              const Text(
                'Key Promises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_manifestoPromises.length, (index) {
                final promise = _manifestoPromises[index];
                if (promise.isEmpty) return const SizedBox.shrink();
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
                          '• $promise',
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
              }),
            ],

            const SizedBox(height: 16),

            // Upload Buttons
            if (widget.isEditing) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
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
                        : const Icon(Icons.picture_as_pdf),
                    label: const Text('Upload PDF'),
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
                        : const Icon(Icons.image),
                    label: const Text('Upload Image'),
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
                          : const Icon(Icons.video_call),
                      label: const Text('Upload Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
                      label: const Text('Premium Video'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purple),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                ],
              ),
            ],

            // Display uploaded files
            if (!widget.isEditing) ...[
              if (data.extraInfo?.manifesto?.pdfUrl != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    // TODO: Open PDF viewer
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('View Manifesto PDF'),
                ),
              ],
              if (data.extraInfo?.manifesto?.images != null && data.extraInfo!.manifesto!.images!.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        insetPadding: const EdgeInsets.all(10),
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              data.extraInfo!.manifesto!.images!.first,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: DecorationImage(
                        image: NetworkImage(data.extraInfo!.manifesto!.images!.first),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ],
              if (data.extraInfo?.manifesto?.videoUrl != null && data.extraInfo!.manifesto!.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 200,
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