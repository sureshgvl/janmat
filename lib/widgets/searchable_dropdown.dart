import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final Function(T?) onChanged;
  final bool enabled;
  final String? Function(T?)? validator;
  final VoidCallback? onTap;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    this.value,
    required this.onChanged,
    this.enabled = true,
    this.validator,
    this.onTap,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isDropdownOpen = false;
  List<DropdownMenuItem<T>> _filteredItems = [];
  bool _isDisposed = false;
  late final _KeyboardVisibilityObserver _keyboardObserver;
  bool _shouldFocusSearchField = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);

    // Initialize keyboard observer
    _keyboardObserver = _KeyboardVisibilityObserver(
      onKeyboardVisibilityChanged: _handleKeyboardVisibility,
    );

    // Listen for keyboard visibility changes
    WidgetsBinding.instance.addObserver(_keyboardObserver);
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredItems = widget.items;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _searchFocus.dispose();
    _removeOverlay();
    WidgetsBinding.instance.removeObserver(_keyboardObserver);
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
    // Ensure overlay is updated if it's open
    if (_isDropdownOpen) {
      _updateOverlay();
    }
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      // Remove current overlay
      _overlayEntry!.remove();
      _overlayEntry = null;

      // Recreate overlay with new position
      if (_isDropdownOpen) {
        _showOverlay();
      }
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      // Call onTap callback before showing overlay
      widget.onTap?.call();
      _showOverlay();
    }
  }

  void _handleKeyboardVisibility() {
    if (_isDropdownOpen) {
      // Update overlay position when keyboard visibility changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDropdownOpen && !_isDisposed) {
          _updateOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Get screen size and keyboard insets
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calculate available space
    final availableHeight = screenSize.height - keyboardHeight - offset.dy - size.height - 50; // 50 for padding
    final maxHeight = availableHeight > 0 ? availableHeight.clamp(100, 350).toDouble() : 200.0;

    // Determine if dropdown should open upwards or downwards
    final spaceBelow = screenSize.height - offset.dy - size.height - keyboardHeight;
    final spaceAbove = offset.dy;
    final shouldOpenUpwards = spaceBelow < 100 && spaceAbove > spaceBelow;

    final topPosition = shouldOpenUpwards
        ? offset.dy - maxHeight
        : offset.dy + size.height;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: topPosition,
        width: size.width,
        child: Material(
          elevation: 4,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onTap: () {
                      // Ensure focus when user taps on search field
                      _searchFocus.requestFocus();
                    },
                  ),
                ),
                // Items list
                Expanded(
                  child: _filteredItems.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final isSelected = item.value == widget.value;
                            return InkWell(
                              onTap: () {
                                widget.onChanged(item.value);
                                _removeOverlay();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: isSelected ? Colors.blue.shade50 : null,
                                child: Row(
                                  children: [
                                    Expanded(child: item.child),
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        color: Colors.blue.shade600,
                                        size: 20,
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

    Overlay.of(context).insert(_overlayEntry!);
    if (!_isDisposed) {
      setState(() => _isDropdownOpen = true);
    }

    // Don't auto-focus search field - let user tap it manually
    // This prevents the keyboard from appearing immediately
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_isDisposed) {
      setState(() => _isDropdownOpen = false);
    }
    _searchController.clear();
    _filteredItems = widget.items;
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

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: widget.enabled ? _toggleDropdown : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey.shade200,
            enabled: widget.enabled,
            suffixIcon: Icon(
              _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
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
      ),
    );
  }
}

class _KeyboardVisibilityObserver extends WidgetsBindingObserver {
  final VoidCallback onKeyboardVisibilityChanged;

  _KeyboardVisibilityObserver({required this.onKeyboardVisibilityChanged});

  @override
  void didChangeMetrics() {
    // Called when keyboard visibility changes
    onKeyboardVisibilityChanged();
  }
}