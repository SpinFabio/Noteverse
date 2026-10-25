import 'package:flutter/material.dart';

import '../theme/noteverse_colors.dart';

/// Shared floating zoom and origin controls for graph canvases.
class CanvasNavigationControls extends StatelessWidget {
  const CanvasNavigationControls({
    required this.onZoomOut,
    required this.onCenter,
    required this.onZoomIn,
    super.key,
  });

  final VoidCallback onZoomOut;
  final VoidCallback onCenter;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) => Material(
    color: NoteverseColors.of(context).floatingControlSurface,
    elevation: 6,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onZoomOut,
          tooltip: 'Zoom out',
          icon: const Icon(Icons.remove),
        ),
        IconButton(
          onPressed: onCenter,
          tooltip: 'Center on origin',
          icon: const Icon(Icons.center_focus_strong),
        ),
        IconButton(
          onPressed: onZoomIn,
          tooltip: 'Zoom in',
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}
