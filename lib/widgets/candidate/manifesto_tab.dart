import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:translator/translator.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/candidate_model.dart';
import '../../services/demo_data_service.dart';
import '../../controllers/candidate_data_controller.dart';

class ManifestoTab extends StatefulWidget {
  final Candidate candidate;

  const ManifestoTab({
    Key? key,
    required this.candidate,
  }) : super(key: key);

  @override
  State<ManifestoTab> createState() => _ManifestoTabState();
}

class _ManifestoTabState extends State<ManifestoTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final GoogleTranslator _translator = GoogleTranslator();
  String _currentLanguage = 'en'; // 'en' for English, 'mr' for Marathi
  String _translatedText = '';
  bool _isTranslating = false;
  String? _originalText;

  // Voter interaction state
  bool _isLiked = false;
  int _likeCount = 0;
  String? _selectedPollOption;
  final Map<String, int> _pollOptions = {
    'development': 0,
    'transparency': 0,
    'youth_education': 0,
    'women_safety': 0,
  };

  @override
  void initState() {
    super.initState();
    // Use the first manifesto item's title or fallback to main manifesto
    final manifestoPromises = widget.candidate.extraInfo?.manifesto?.promises ?? [];
    _originalText = manifestoPromises.isNotEmpty
        ? manifestoPromises.first
        : widget.candidate.manifesto ?? '';
    _translatedText = _originalText ?? '';
  }

  @override
  void didUpdateWidget(ManifestoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final manifestoPromises = widget.candidate.extraInfo?.manifesto?.promises ?? [];
    final newText = manifestoPromises.isNotEmpty
        ? manifestoPromises.first
        : widget.candidate.manifesto ?? '';
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

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    // Award XP for supporting manifesto
    if (_isLiked) {
      Get.snackbar(
        'XP Earned! 🎉',
        'You earned 10 XP for supporting this manifesto',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _selectPollOption(String option) {
    setState(() {
      _selectedPollOption = option;
      _pollOptions[option] = (_pollOptions[option] ?? 0) + 1;
    });

    Get.snackbar(
      'Thank you! 🙏',
      'Your feedback has been recorded',
      backgroundColor: Colors.blue.shade100,
      colorText: Colors.blue.shade800,
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildPollOption(String optionKey, String optionText) {
    final isSelected = _selectedPollOption == optionKey;
    final voteCount = _pollOptions[optionKey] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectPollOption(optionKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  optionText,
                  style: TextStyle(
                    color: isSelected ? Colors.blue.shade800 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (voteCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$voteCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final manifestoPromises = widget.candidate.extraInfo?.manifesto?.promises ?? [];
    final manifesto = widget.candidate.manifesto ?? '';

    // Use demo manifesto items if no real items exist
    final displayManifestoPromises = manifestoPromises.isNotEmpty
        ? manifestoPromises.map((promise) => promise.toString()).toList()
        : DemoDataService.getDemoManifestoPromises('development', 'en');

    final hasStructuredData = displayManifestoPromises.isNotEmpty || manifesto.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasStructuredData || manifesto.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.gavel_outlined,
                              color: Colors.red.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Manifesto',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Display Manifesto Title
                      if (widget.candidate.extraInfo?.manifesto?.title != null && widget.candidate.extraInfo!.manifesto!.title!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            widget.candidate.extraInfo!.manifesto!.title!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.candidate.extraInfo?.manifesto?.pdfUrl != null && widget.candidate.extraInfo!.manifesto!.pdfUrl!.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                final url = widget.candidate.extraInfo!.manifesto!.pdfUrl!;
                                if (await canLaunch(url)) {
                                  await launch(url);
                                }
                              },
                              icon: const Icon(Icons.download, color: Colors.blue),
                              tooltip: 'Download PDF',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          // Language Toggle Buttons - More compact
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    onPressed: _currentLanguage == 'en' ? null : () => _changeLanguage('en'),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _currentLanguage == 'en'
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                      foregroundColor: _currentLanguage == 'en'
                                          ? Colors.white
                                          : Colors.grey[700],
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'EN',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 16,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(
                                  height: 32,
                                  child: TextButton(
                                    onPressed: _currentLanguage == 'mr' ? null : () => _changeLanguage('mr'),
                                    style: TextButton.styleFrom(
                                      backgroundColor: _currentLanguage == 'mr'
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                      foregroundColor: _currentLanguage == 'mr'
                                          ? Colors.white
                                          : Colors.grey[700],
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: const Size(0, 32),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'मराठी',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Display Manifesto Items
                  if (manifestoPromises.isNotEmpty) ...[
                    const Text(
                      'Key Promises',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(manifestoPromises.length, (index) {
                        final promise = manifestoPromises[index];
                        if (promise.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      promise,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.4,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Display Manifesto Text
                  if (manifesto.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isTranslating
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : MarkdownBody(
                              data: _translatedText,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151),
                                  height: 1.7,
                                  letterSpacing: 0.3,
                                ),
                                strong: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF374151),
                                  height: 1.7,
                                  letterSpacing: 0.3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ],

                  // Voter Interaction Section
                  const SizedBox(height: 24),
                  Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Like/Support Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _toggleLike,
                                icon: Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.grey,
                                ),
                                label: Text(
                                  _isLiked ? 'Supported (${_likeCount})' : 'Support This Manifesto',
                                  style: TextStyle(
                                    color: _isLiked ? Colors.red : Colors.black,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isLiked ? Colors.red.shade50 : Colors.white,
                                  side: BorderSide(
                                    color: _isLiked ? Colors.red.shade300 : Colors.grey.shade300,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Poll Section
                          const Text(
                            'What issue matters most to you?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              _buildPollOption('development', 'Development & Infrastructure'),
                              _buildPollOption('transparency', 'Transparency & Governance'),
                              _buildPollOption('youth_education', 'Youth & Education'),
                              _buildPollOption('women_safety', 'Women & Safety'),
                            ],
                          ),
                        ],
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