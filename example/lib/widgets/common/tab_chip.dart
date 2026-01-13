/// Tab chip widget for displaying selectable tabs.
library;

import 'package:flutter/material.dart';

/// A chip widget for displaying a tab selection state.
class TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const TabChip({
    super.key,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor:
          isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
    );
  }
}
