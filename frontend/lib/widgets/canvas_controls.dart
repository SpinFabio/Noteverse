import 'package:flutter/material.dart';

/// Top-left command surface for actions related to the graph canvas.
class CanvasControls extends StatelessWidget {
  const CanvasControls({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 2,
    borderRadius: BorderRadius.circular(12),
    child: IconButton(
      onPressed: onOpenSettings,
      tooltip: 'Graph view settings',
      icon: const Icon(Icons.settings_outlined),
    ),
  );
}
