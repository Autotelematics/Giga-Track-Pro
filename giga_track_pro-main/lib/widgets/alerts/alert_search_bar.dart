import 'package:flutter/material.dart';
import 'package:trackerapp/providers/get_alert_provider.dart';

class AlertSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final AlertsProvider provider;
  final VoidCallback onSearchChanged;

  const AlertSearchBar({
    super.key,
    required this.controller,
    required this.provider,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          provider.setSearchQuery(value);
          onSearchChanged();
        },
        decoration: InputDecoration(
          labelText: 'Search Vehicle or Alert',
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              provider.setSearchQuery(null);
              onSearchChanged();
            },
          )
              : const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}