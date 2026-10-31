import 'package:flutter/material.dart';

import '../graph/models/graph_view_mode.dart';
import '../theme/noteverse_colors.dart';

/// Switches the main canvas between navigation, exploration, and editing.
class GraphViewModeControls extends StatelessWidget {
  const GraphViewModeControls({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final GraphViewMode mode;
  final ValueChanged<GraphViewMode> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color: NoteverseColors.of(context).floatingControlSurface,
    elevation: 6,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: SegmentedButton<GraphViewMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: GraphViewMode.navigate,
          icon: Icon(Icons.pan_tool_outlined),
          label: Text('Navigate'),
        ),
        ButtonSegment(
          value: GraphViewMode.explore,
          icon: Icon(Icons.explore_outlined),
          label: Text('Explore'),
        ),
        ButtonSegment(
          value: GraphViewMode.edit,
          icon: Icon(Icons.edit_outlined),
          label: Text('Edit'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.single),
    ),
  );
}
