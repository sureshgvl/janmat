import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../../models/candidate_model.dart';

class ManifestoSection extends StatefulWidget {
  final Candidate candidateData;
  final Candidate? editedData;
  final bool isEditing;
  final Function(String) onManifestoChange;
  final Function(String) onManifestoPdfChange;

  const ManifestoSection({
    super.key,
    required this.candidateData,
    this.editedData,
    required this.isEditing,
    required this.onManifestoChange,
    required this.onManifestoPdfChange,
  });

  @override
  State<ManifestoSection> createState() => _ManifestoSectionState();
}

class _ManifestoSectionState extends State<ManifestoSection> {
  final GoogleTranslator _translator = GoogleTranslator();
  String _currentLanguage = 'en'; // 'en' for English, 'mr' for Marathi
  String _translatedText = '';
  bool _isTranslating = false;
  String? _originalText;

  @override
  void initState() {
    super.initState();
    final data = widget.editedData ?? widget.candidateData;
    _originalText = data.extraInfo?.manifesto ?? '';
    _translatedText = _originalText ?? '';
  }

  @override
  void didUpdateWidget(ManifestoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final data = widget.editedData ?? widget.candidateData;
    final newText = data.extraInfo?.manifesto ?? '';
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
    final data = widget.editedData ?? widget.candidateData;
    final manifesto = data.extraInfo?.manifesto ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manifesto',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!widget.isEditing && manifesto.isNotEmpty)
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
            if (widget.isEditing)
              TextFormField(
                initialValue: manifesto,
                decoration: const InputDecoration(
                  labelText: 'Manifesto',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                onChanged: widget.onManifestoChange,
              )
            else
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
                        manifesto.isNotEmpty ? _translatedText : 'No manifesto available',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.isEditing ? () {
                // TODO: Implement PDF upload
                widget.onManifestoPdfChange('https://example.com/manifesto.pdf');
              } : null,
              child: const Text('Upload Manifesto PDF'),
            ),
          ],
        ),
      ),
    );
  }
}