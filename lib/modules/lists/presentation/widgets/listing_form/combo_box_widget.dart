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
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _filteredItems = widget.items;
  }

  @override
  void didUpdateWidget(ComboBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: (value) {
        _filterItems(value);
        widget.onChanged(value.isEmpty ? null : value);
      },
      onTap: () {
        setState(() {
          _filteredItems = widget.items;
        });
      },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down),
          enabled: widget.enabled,
          onSelected: (value) {
            _controller.text = value;
            widget.onChanged(value);
          },
          itemBuilder: (context) {
            if (_filteredItems.isEmpty) {
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'No matches found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ];
            }
            return _filteredItems.map((item) {
              return PopupMenuItem<String>(value: item, child: Text(item));
            }).toList();
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
