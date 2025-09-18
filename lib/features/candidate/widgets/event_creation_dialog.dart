import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/candidate_model.dart';
import '../controllers/candidate_data_controller.dart';
import '../repositories/candidate_repository.dart';

class EventCreationDialog extends StatefulWidget {
  final EventData? eventToEdit;
  final String candidateId;
  final Function(EventData) onEventSaved;

  const EventCreationDialog({
    super.key,
    this.eventToEdit,
    required this.candidateId,
    required this.onEventSaved,
  });

  @override
  State<EventCreationDialog> createState() => _EventCreationDialogState();
}

class _EventCreationDialogState extends State<EventCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final CandidateRepository _candidateRepository = CandidateRepository();
  final CandidateDataController _controller =
      Get.find<CandidateDataController>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _mapLinkController;
  late TextEditingController _timeController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.eventToEdit?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.eventToEdit?.description ?? '',
    );
    _venueController = TextEditingController(
      text: widget.eventToEdit?.venue ?? '',
    );
    _mapLinkController = TextEditingController(
      text: widget.eventToEdit?.mapLink ?? '',
    );
    _timeController = TextEditingController(
      text: widget.eventToEdit?.time ?? '',
    );

    if (widget.eventToEdit != null) {
      _selectedDate = DateTime.tryParse(widget.eventToEdit!.date);
      if (widget.eventToEdit!.time != null &&
          widget.eventToEdit!.time!.isNotEmpty) {
        final timeParts = widget.eventToEdit!.time!.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _mapLinkController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      Get.snackbar('Error', 'Please select a date for the event');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        '🎪 Event Creation: Starting save process for candidateId: ${widget.candidateId}',
      );

      final eventData = EventData(
        id:
            widget.eventToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        time: _timeController.text.isNotEmpty ? _timeController.text : null,
        venue: _venueController.text.isNotEmpty
            ? _venueController.text.trim()
            : null,
        mapLink: _mapLinkController.text.isNotEmpty
            ? _mapLinkController.text.trim()
            : null,
        type: 'public_event',
        status: 'upcoming',
        rsvp:
            widget.eventToEdit?.rsvp ??
            {'interested': [], 'going': [], 'not_going': []},
      );

      debugPrint(
        '📝 Event Data Created: ${eventData.title} on ${eventData.date}',
      );

      // Ensure user document exists before proceeding
      debugPrint('🔧 Ensuring user document exists for: ${widget.candidateId}');
      await _candidateRepository.ensureUserDocumentExists(widget.candidateId);

      // Get current candidate data by candidateId
      debugPrint(
        '🔍 Getting candidate data for candidateId: ${widget.candidateId}',
      );
      final candidate = await _candidateRepository.getCandidateDataById(
        widget.candidateId,
      );
      if (candidate == null) {
        debugPrint(
          '❌ Candidate lookup failed for candidateId: ${widget.candidateId}',
        );
        throw Exception(
          'Unable to load candidate data. Please ensure your profile is complete and try again.',
        );
      }

      debugPrint(
        '✅ Found candidate: ${candidate.name} (ID: ${candidate.candidateId})',
      );

      // Update events in extra_info
      final currentEvents = candidate.extraInfo?.events ?? [];
      final updatedEvents = List<EventData>.from(currentEvents);

      // Remove existing event if editing
      if (widget.eventToEdit != null) {
        updatedEvents.removeWhere((e) => e.id == widget.eventToEdit!.id);
      }

      // Add/update the event
      updatedEvents.add(eventData);

      // Update candidate extra info
      final updatedExtraInfo =
          candidate.extraInfo?.copyWith(events: updatedEvents) ??
          ExtraInfo(events: updatedEvents);

      final updatedCandidate = candidate.copyWith(extraInfo: updatedExtraInfo);

      final success = await _candidateRepository.updateCandidateExtraInfo(
        updatedCandidate,
      );

      if (success) {
        // Refresh the controller's events cache
        await _controller.refreshEvents();

        widget.onEventSaved(eventData);
        Get.back();
        Get.snackbar(
          'Success',
          widget.eventToEdit != null
              ? 'Event updated successfully'
              : 'Event created successfully',
        );
      } else {
        throw Exception('Failed to save event');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save event: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.eventToEdit != null
                        ? 'Edit Event'
                        : 'Create New Event',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      hintText: 'e.g., जनसंपर्क सभा – वारजे',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Event title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Field
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Date *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time Field
                  InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select time (optional)',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? Colors.black
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Venue Field
                  TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(
                      labelText: 'Venue',
                      hintText: 'e.g., वारजे बस स्टँड जवळ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Map Link Field
                  TextFormField(
                    controller: _mapLinkController,
                    decoration: const InputDecoration(
                      labelText: 'Google Maps Link',
                      hintText: 'https://maps.app.goo.gl/...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Additional details about the event',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.eventToEdit != null
                                    ? 'Update Event'
                                    : 'Create Event',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
