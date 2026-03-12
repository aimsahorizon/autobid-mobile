import 'package:flutter/material.dart';

class ComboBoxWidget extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? hint;

  const ComboBoxWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  @override
  State<ComboBoxWidget> createState() => _ComboBoxWidgetState();
}

class _ComboBoxWidgetState extends State<ComboBoxWidget> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<String> _filteredItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _filteredItems = widget.items;
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(ComboBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
    if (widget.items != oldWidget.items) {
      _filteredItems = _filterList(_controller.text);
      _rebuildOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _filteredItems = _filterList(_controller.text);
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  List<String> _filterList(String query) {
    if (query.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _showOverlay() {
    _removeOverlay();
    if (_filteredItems.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = item == _controller.text;
                  return InkWell(
                    onTap: () => _selectItem(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isOpen = true;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _rebuildOverlay() {
    if (_isOpen) {
      _removeOverlay();
      if (_focusNode.hasFocus && _filteredItems.isNotEmpty) {
        _showOverlay();
      }
    }
  }

  void _selectItem(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    widget.onChanged(value);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
      _focusNode.unfocus();
    } else {
      _filteredItems = widget.items;
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        validator: widget.validator,
        autovalidateMode: widget.validator != null
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        onChanged: (value) {
          _filteredItems = _filterList(value);
          widget.onChanged(value.isEmpty ? null : value);
          _rebuildOverlay();
          if (!_isOpen && _filteredItems.isNotEmpty) {
            _showOverlay();
          }
        },
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_drop_down),
            onPressed: widget.enabled ? _toggleDropdown : null,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
