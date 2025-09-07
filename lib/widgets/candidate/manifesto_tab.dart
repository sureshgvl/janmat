import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:translator/translator.dart';
import '../../models/candidate_model.dart';

class ManifestoTab extends StatefulWidget {
  final Candidate candidate;

  const ManifestoTab({
    Key? key,
    required this.candidate,
  }) : super(key: key);

  @override
  State<ManifestoTab> createState() => _ManifestoTabState();
}

class _ManifestoTabState extends State<ManifestoTab> {
  final GoogleTranslator _translator = GoogleTranslator();
  String _currentLanguage = 'en'; // 'en' for English, 'mr' for Marathi
  String _translatedText = '';
  bool _isTranslating = false;
  String? _originalText;

  @override
  void initState() {
    super.initState();
    _originalText = widget.candidate.manifesto ?? '';
    _translatedText = _originalText ?? '';
  }

  @override
  void didUpdateWidget(ManifestoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.candidate.manifesto ?? '';
    if (_originalText != newText) {
      _originalText = newText;
      if (_currentLanguage == 'en') {
        _translatedText = newText;
      } else {
        _translateText(newText, _currentLanguage);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final manifesto = widget.candidate.manifesto ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (manifesto.isNotEmpty)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Manifesto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      Row(
                        children: [
                          if (widget.candidate.extraInfo?.manifestoPdf != null && widget.candidate.extraInfo!.manifestoPdf!.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                final url = widget.candidate.extraInfo!.manifestoPdf!;
                                if (await canLaunch(url)) {
                                  await launch(url);
                                }
                              },
                              icon: const Icon(Icons.download, color: Colors.blue),
                              tooltip: 'Download PDF',
                            ),
                          const SizedBox(width: 8),
                          // Language Toggle Buttons
                          ElevatedButton(
                            onPressed: _currentLanguage == 'en' ? null : () => _changeLanguage('en'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentLanguage == 'en'
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
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
                                  : Colors.grey.shade300,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _isTranslating
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Text(
                            _translatedText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                              height: 1.6,
                            ),
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