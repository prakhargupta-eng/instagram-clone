import 'package:flutter/material.dart';
import '../../adaptive_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = TextEditingController();
  String _text = '';

  static const _suggestions = <String>[
    'Mumbai, India',
    'Delhi, India',
    'Bengaluru, India',
    'New York, USA',
    'Los Angeles, USA',
    'London, UK',
    'Paris, France',
    'Tokyo, Japan',
    'Dubai, UAE',
    'Sydney, Australia',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _text.isEmpty
        ? _suggestions
        : _suggestions
              .where((s) => s.toLowerCase().contains(_text.toLowerCase()))
              .toList();

    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Select Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: TextStyle(color: context.textPrimaryColor),
                onChanged: (value) => setState(() => _text = value.trim()),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) {
                    Navigator.of(context).pop(trimmed);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Search for a location',
                  hintStyle: TextStyle(color: context.textSecondaryColor),
                  prefixIcon: Icon(Icons.search, color: context.textSecondaryColor),
                  filled: true,
                  fillColor: context.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (suggestions.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    for (final suggestion in suggestions)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: context.textSecondaryColor,
                        ),
                        title: Text(
                          suggestion,
                          style: TextStyle(fontSize: 14, color: context.textPrimaryColor),
                        ),
                        onTap: () => Navigator.of(context).pop(suggestion),
                      ),
                  ],
                ),
              ),
            if (suggestions.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No locations found',
                    style: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
