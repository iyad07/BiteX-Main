import 'package:flutter/material.dart';

class SearchBarField extends StatefulWidget {
  final bool enabled;
  final String query;
  final ValueChanged<String> onSearchChanged;

  const SearchBarField
  ({
    super.key,
    this.enabled = true,
    required this.query,
    required this.onSearchChanged,
  });

  @override
  State<SearchBarField
  > createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBarField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      onChanged: widget.onSearchChanged,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search dishes, restaurants',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
