import 'package:flutter/material.dart';

import '../theme/noteverse_colors.dart';

/// Top-left command surface for actions related to the graph canvas.
class CanvasControls extends StatelessWidget {
  const CanvasControls({required this.onOpenSettings, super.key});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Material(
    color: NoteverseColors.of(context).floatingControlSurface,
    elevation: 6,
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      onPressed: onOpenSettings,
      tooltip: 'Graph view settings',
      icon: const Icon(Icons.settings_outlined),
    ),
  );
}
