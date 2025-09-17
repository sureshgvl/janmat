import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

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
  void _addNewPromise() {
    debugPrint('Add New Promise button pressed');
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
    debugPrint(
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
    debugPrint(
      'Deleted promise at index $index, remaining promises: ${widget.promiseControllers.length}',
    );
  }

  void _addPointToPromise(int promiseIndex) {
    debugPrint('Add Point button pressed for promise $promiseIndex');
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
    debugPrint(
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
                                onPressed: () {
                                  // TODO: Implement demo template functionality
                                },
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
