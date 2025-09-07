import 'package:flutter/material.dart';

class ModalSelector<T> extends StatefulWidget {
  final String title;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final Function(T?) onChanged;
  final bool enabled;
  final String? Function(T?)? validator;
  final String? label;

  const ModalSelector({
    super.key,
    required this.title,
    required this.hint,
    required this.items,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.validator,
    this.label,
  });

  @override
  State<ModalSelector<T>> createState() => _ModalSelectorState<T>();
}

class _ModalSelectorState<T> extends State<ModalSelector<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<DropdownMenuItem<T>> _filteredItems = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void didUpdateWidget(ModalSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        final itemText = item.child.toString().toLowerCase();
        return itemText.contains(query);
      }).toList();
    });
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search field
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.title.toLowerCase()}...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      // Trigger rebuild of the modal when search text changes
                      setState(() {});
                    },
                  ),
                ),

                // Items list
                Expanded(
                  child: _filteredItems.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found for "${_searchController.text}"',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = item.value == widget.value;

                            return InkWell(
                              onTap: () {
                                widget.onChanged(item.value);
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: item.child),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).primaryColor,
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDisplayText(DropdownMenuItem<T>? item) {
    if (item == null) return widget.hint;

    // Extract text from Text widget
    if (item.child is Text) {
      return (item.child as Text).data ?? '';
    }

    // Fallback to toString for other widget types
    return item.child.toString();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
          (item) => item?.value == widget.value,
          orElse: () => null,
        );

    return InkWell(
      onTap: widget.enabled ? _showModal : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: widget.enabled ? Colors.white : Colors.grey.shade200,
          enabled: widget.enabled,
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: widget.enabled ? null : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _getDisplayText(selectedItem),
                style: TextStyle(
                  color: selectedItem != null ? null : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}