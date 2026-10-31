import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../graph/layout/force_graph_layout.dart';
import '../graph/models/graph_data.dart';
import '../hex_grid_geometry.dart';
import '../hex_grid_lines.dart';
import '../theme/noteverse_colors.dart';
import '../theme/noteverse_graph_style.dart';
import '../theme/noteverse_typography.dart';
import 'canvas_navigation_controls.dart';

/// Opens the temporary force-directed graph arrangement workspace.
Future<GraphData?> showGraphLayoutDialog({
  required BuildContext context,
  required GraphData graph,
  required HexGridGeometry geometry,
  required Color backgroundColor,
}) => showDialog<GraphData>(
  context: context,
  barrierDismissible: true,
  builder: (context) => GraphLayoutDialog(
    graph: graph,
    geometry: geometry,
    backgroundColor: backgroundColor,
  ),
);

/// Overlay modal for relaxing, editing, and snapping a graph layout.
class GraphLayoutDialog extends StatefulWidget {
  const GraphLayoutDialog({
    required this.graph,
    required this.geometry,
    required this.backgroundColor,
    super.key,
  });

  final GraphData graph;
  final HexGridGeometry geometry;
  final Color backgroundColor;

  @override
  State<GraphLayoutDialog> createState() => _GraphLayoutDialogState();
}

class _GraphLayoutDialogState extends State<GraphLayoutDialog>
    with SingleTickerProviderStateMixin {
  late final ForceGraphLayout _layout = ForceGraphLayout(
    graph: widget.graph,
    geometry: widget.geometry,
  );
  late final Ticker _ticker;
  Duration? _previousElapsed;
  String? _draggedNodeId;
  double _viewScale = 1;
  Offset _viewTranslation = Offset.zero;
  bool _isPanning = false;

  static const _minimumViewScale = 0.25;
  static const _maximumViewScale = 4.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_advanceLayout)..start();
  }

  void _advanceLayout(Duration elapsed) {
    final previousElapsed = _previousElapsed;
    _previousElapsed = elapsed;
    if (previousElapsed == null) {
      return;
    }

    _layout.advance((elapsed - previousElapsed).inMicroseconds / 1000000);
    if (!_layout.isRunning) {
      _ticker.stop();
    }
  }

  void _stop() {
    _layout.stop();
    _ticker.stop();
    setState(() {});
  }

  void _start() {
    _previousElapsed = null;
    _layout.start();
    if (!_ticker.isActive) {
      _ticker.start();
    }
    setState(() {});
  }

  void _reset() {
    _draggedNodeId = null;
    _previousElapsed = null;
    _layout.reset();
    _ticker.stop();
    setState(() {});
  }

  Future<void> _confirmReset() async {
    final wasRunning = _layout.isRunning;
    _stop();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: NoteverseColors.of(
        context,
      ).graphBackground.withValues(alpha: 0.8),
      builder: (context) => AlertDialog(
        title: const Text('Reset graph layout?'),
        content: const Text(
          'Restore the initial node positions? Your current arrangement '
          'will be lost. The simulation will remain stopped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (confirmed == true) {
      _reset();
    } else if (wasRunning) {
      _start();
    }
  }

  void _snapToGrid() {
    _layout.snapToGrid();
    _ticker.stop();
    setState(() {});
  }

  void _returnToForces() {
    _layout.returnToForces();
    _ticker.stop();
    setState(() {});
  }

  void _updateParameters(ForceGraphLayoutParameters parameters) {
    _layout.updateParameters(parameters);
    setState(() {});
  }

  Offset _layoutPositionFromScreen(Offset position, Size size) {
    return (position - size.center(Offset.zero) - _viewTranslation) /
        _viewScale;
  }

  void _startInteraction(DragStartDetails details, Size size) {
    final layoutPosition = _layoutPositionFromScreen(
      details.localPosition,
      size,
    );
    final nodeId = _layout.hitTestNode(layoutPosition);
    if (nodeId == null) {
      _isPanning = true;
      setState(() {});
      return;
    }
    _draggedNodeId = nodeId;
    _layout.beginDrag(nodeId);
    setState(() {});
  }

  void _updateInteraction(DragUpdateDetails details, Size size) {
    if (_isPanning) {
      setState(() => _viewTranslation += details.delta);
      return;
    }
    if (_draggedNodeId != null) {
      _layout.updateDraggedNode(
        _layoutPositionFromScreen(details.localPosition, size),
      );
    }
  }

  void _endInteraction() {
    if (_isPanning) {
      _isPanning = false;
      setState(() {});
      return;
    }
    if (_draggedNodeId != null) {
      _layout.endDrag();
      _draggedNodeId = null;
      setState(() {});
    }
  }

  void _zoomAt(Offset focalPoint, Size size, double factor) {
    final worldPoint = _layoutPositionFromScreen(focalPoint, size);
    final nextScale = (_viewScale * factor).clamp(
      _minimumViewScale,
      _maximumViewScale,
    );
    final screenCenter = size.center(Offset.zero);
    setState(() {
      _viewScale = nextScale;
      _viewTranslation = focalPoint - screenCenter - worldPoint * nextScale;
    });
  }

  void _zoomWithWheel(PointerScrollEvent event, Size size) {
    _zoomAt(event.localPosition, size, math.exp(-event.scrollDelta.dy * 0.001));
  }

  void _centerView() {
    setState(() => _viewTranslation = Offset.zero);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _layout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final dialogWidth = (viewport.width * 0.84).clamp(720.0, 1280.0);
    final dialogHeight = (viewport.height * 0.82).clamp(560.0, 900.0);
    final colors = NoteverseColors.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        // Reserve real hit-test space for the close button outside the surface.
        child: Stack(
          children: [
            Positioned.fill(
              top: 20,
              right: 20,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(child: _buildCanvas(colors)),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(context),
                          const Divider(height: 1),
                          Expanded(child: _buildParameterPanel(context)),
                          _buildApplyFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close without applying',
                style: IconButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  backgroundColor: colors.floatingControlSurface,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.75,
                  ),
                ),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: AnimatedBuilder(
        animation: _layout,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arrange graph',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 3),
            Text(_phaseLabel, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }

  /// Keeps the apply action outside the scrolling parameter area.
  Widget _buildApplyFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _layout,
              builder: (context, _) => FilledButton(
                onPressed: _layout.canApply
                    ? () => Navigator.pop(context, _layout.buildGraph())
                    : null,
                child: const Text('Apply'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas(NoteverseColors colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MouseRegion(
                cursor: _draggedNodeId == null && !_isPanning
                    ? SystemMouseCursors.grab
                    : SystemMouseCursors.grabbing,
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _zoomWithWheel(event, size);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) => _startInteraction(details, size),
                    onPanUpdate: (details) => _updateInteraction(details, size),
                    onPanEnd: (_) => _endInteraction(),
                    onPanCancel: _endInteraction,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _ForceGraphPainter(
                          layout: _layout,
                          geometry: widget.geometry,
                          viewScale: _viewScale,
                          viewTranslation: _viewTranslation,
                          backgroundColor: widget.backgroundColor,
                          gridColor: colors.graphGridLines,
                          gridLineWidth: NoteverseGraphStyle.gridLineWidth,
                          nodeSurfaceColor: colors.graphNodeSurface,
                          nodeOutlineColor: colors.graphNodeOutline,
                          nodeLabelColor: colors.graphNodeLabel,
                          edgeColor: colors.graphEdge,
                        ),
                        size: size,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _buildPreviewControls(colors, size),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: colors.floatingControlSurface,
                  elevation: 6,
                  shape: const StadiumBorder(),
                  child: OutlinedButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewControls(NoteverseColors colors, Size viewportSize) {
    return AnimatedBuilder(
      animation: _layout,
      builder: (context, _) {
        final zoomControls = CanvasNavigationControls(
          onZoomOut: () =>
              _zoomAt(viewportSize.center(Offset.zero), viewportSize, 0.8),
          onCenter: _centerView,
          onZoomIn: () =>
              _zoomAt(viewportSize.center(Offset.zero), viewportSize, 1.25),
        );
        final simulationControls = Material(
          color: colors.floatingControlSurface,
          elevation: 6,
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SimulationStatusButton(
                  active: _layout.isRunning,
                  idleLabel: 'Start',
                  activeLabel: 'Running',
                  icon: Icons.play_arrow,
                  statusColor: colors.simulationRunning,
                  onPressed: _start,
                ),
                const SizedBox(width: 4),
                _SimulationStatusButton(
                  active: !_layout.isRunning,
                  idleLabel: 'Stop',
                  activeLabel: 'Stopped',
                  icon: Icons.stop,
                  statusColor: Theme.of(context).colorScheme.error,
                  onPressed: _stop,
                ),
              ],
            ),
          ),
        );
        final modeControl = _layout.mode == GraphLayoutMode.forces
            ? FilledButton.icon(
                onPressed: _layout.canSnap ? _snapToGrid : null,
                icon: const Icon(Icons.grid_view_outlined),
                label: const Text('Snap to grid'),
              )
            : FilledButton.icon(
                onPressed: _returnToForces,
                icon: const Icon(Icons.undo),
                label: const Text('Back to forces'),
              );

        return LayoutBuilder(
          builder: (context, constraints) {
            final showSimulation = _layout.mode == GraphLayoutMode.forces;
            // Use two rows on narrow previews so floating controls never overlap.
            if (constraints.maxWidth < 800 && showSimulation) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  simulationControls,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [zoomControls, modeControl],
                  ),
                ],
              );
            }
            return SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(alignment: Alignment.centerLeft, child: zoomControls),
                  if (showSimulation) simulationControls,
                  Align(alignment: Alignment.centerRight, child: modeControl),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParameterPanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact the six parameter rows before falling back to scrolling.
        // Clamp expansion so tall windows do not spread controls too far apart.
        final theme = Theme.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        double textHeight(String text, TextStyle style, double width) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textScaler: textScaler,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: width);
          final height = painter.height;
          painter.dispose();
          return height;
        }

        double requiredHeight(double density) {
          final padding = 8 + 4 * density;
          final width = constraints.maxWidth - padding * 2;
          final labelHeight = textHeight(
            'Center gravity',
            theme.textTheme.bodyMedium!.copyWith(fontSize: 11 + density),
            width / 2,
          );
          final valueHeight = textHeight(
            '100.0x / 100x',
            theme.textTheme.labelMedium!.copyWith(fontSize: 11 + density),
            width / 2,
          );
          final titleHeight = textHeight(
            'Relaxation',
            theme.textTheme.titleMedium!.copyWith(fontSize: 13 + density),
            width,
          );
          return padding * 2 +
              titleHeight +
              2 +
              4 * density +
              6 *
                  (math.max(labelHeight, valueHeight) +
                      24 +
                      8 * density +
                      2 +
                      4 * density);
        }

        var density = 0.0;
        var upperDensity = 1.0;
        for (var iteration = 0; iteration < 12; iteration++) {
          final candidate = (density + upperDensity) / 2;
          if (requiredHeight(candidate) + 8 <= constraints.maxHeight) {
            density = candidate;
          } else {
            upperDensity = candidate;
          }
        }
        return Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.copyWith(
              bodyMedium: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11 + density,
              ),
              labelMedium: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11 + density,
              ),
              titleMedium: theme.textTheme.titleMedium?.copyWith(
                fontSize: 13 + density,
              ),
            ),
          ),
          child: Builder(
            builder: (context) => DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodyMedium,
              child: _buildParameterContent(context, density),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParameterContent(BuildContext context, double density) {
    final padding = 8 + 4 * density;
    final gap = 2 + 4 * density;
    if (_layout.mode == GraphLayoutMode.hexGrid) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, padding, padding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hex grid', style: Theme.of(context).textTheme.titleMedium),
            Padding(
              padding: EdgeInsets.symmetric(vertical: gap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drag nodes to move them between cells. Occupied cells are '
                    'resolved using the nearest free position.',
                  ),
                  SizedBox(height: gap),
                  const Text(
                    'Apply keeps this layout. Back to forces returns these '
                    'positions to the continuous editor with interactions paused.',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final parameters = _layout.parameters;
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Relaxation', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: gap),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Repulsion',
            value: parameters.repulsion,
            minimum: 0.1,
            maximum: 100,
            divisions: 1000,
            nonlinear: true,
            valueLabel: '${parameters.repulsion.toStringAsFixed(1)}x / 100x',
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(repulsion: value)),
          ),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Attraction',
            value: parameters.attraction,
            minimum: 0.1,
            maximum: 100,
            divisions: 1000,
            nonlinear: true,
            valueLabel: '${parameters.attraction.toStringAsFixed(1)}x / 100x',
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(attraction: value)),
          ),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Link distance',
            value: parameters.linkDistance,
            minimum: 40,
            maximum: 160,
            divisions: 24,
            valueLabel: parameters.linkDistance.round().toString(),
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(linkDistance: value)),
          ),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Center gravity',
            value: parameters.centering,
            minimum: 0,
            maximum: 100,
            divisions: 1000,
            nonlinear: true,
            valueLabel: '${parameters.centering.toStringAsFixed(1)}x / 100x',
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(centering: value)),
          ),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Damping',
            value: parameters.damping,
            minimum: 0.05,
            maximum: 0.45,
            divisions: 40,
            valueLabel: parameters.damping.toStringAsFixed(2),
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(damping: value)),
          ),
          _ParameterSlider(
            bottomGap: 2 + 4 * density,
            controlHeight: 24 + 8 * density,
            label: 'Speed',
            value: parameters.speed,
            minimum: 0.25,
            maximum: 20,
            divisions: 1000,
            nonlinear: true,
            valueLabel: '${parameters.speed.toStringAsFixed(2)}x / 20x',
            onChanged: (value) =>
                _updateParameters(parameters.copyWith(speed: value)),
          ),
        ],
      ),
    );
  }

  String get _phaseLabel {
    if (_layout.mode == GraphLayoutMode.hexGrid) {
      return 'Grid mode - drag nodes between cells';
    }
    if (_layout.isSpawning) {
      return _layout.isRunning ? 'Adding nodes...' : 'Node creation paused';
    }
    return _layout.isRunning
        ? 'Force interactions running...'
        : 'Force interactions frozen - manual drag remains available';
  }
}

/// A disabled status indicator that pulses only while its state is active.
class _SimulationStatusButton extends StatefulWidget {
  const _SimulationStatusButton({
    required this.active,
    required this.idleLabel,
    required this.activeLabel,
    required this.icon,
    required this.statusColor,
    required this.onPressed,
  });

  final bool active;
  final String idleLabel;
  final String activeLabel;
  final IconData icon;
  final Color statusColor;
  final VoidCallback onPressed;

  @override
  State<_SimulationStatusButton> createState() =>
      _SimulationStatusButtonState();
}

class _SimulationStatusButtonState extends State<_SimulationStatusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: 0.65,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(_SimulationStatusButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) {
        _pulse.repeat(reverse: true);
      }
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: OutlinedButton.icon(
      onPressed: widget.active ? null : widget.onPressed,
      style: widget.active
          ? OutlinedButton.styleFrom(
              disabledForegroundColor: widget.statusColor,
              side: BorderSide(color: widget.statusColor),
            )
          : null,
      icon: Icon(widget.icon),
      label: Text(widget.active ? widget.activeLabel : widget.idleLabel),
    ),
  );
}

class _ParameterSlider extends StatelessWidget {
  const _ParameterSlider({
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.nonlinear = false,
    required this.bottomGap,
    required this.controlHeight,
  });

  final String label;
  final double value;
  final double minimum;
  final double maximum;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final double bottomGap;
  final double controlHeight;

  /// Uses a logarithmic curve with an offset so zero remains representable.
  final bool nonlinear;

  double _toSliderValue(double parameter) =>
      math.log(1 + parameter - minimum) / math.log(1 + maximum - minimum);

  double _fromSliderValue(double position) =>
      minimum + math.pow(1 + maximum - minimum, position).toDouble() - 1;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomGap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(valueLabel, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        SizedBox(
          height: controlHeight,
          child: Slider(
            value: nonlinear ? _toSliderValue(value).clamp(0, 1) : value,
            min: nonlinear ? 0 : minimum,
            max: nonlinear ? 1 : maximum,
            divisions: divisions,
            label: valueLabel,
            onChanged: (position) => onChanged(
              nonlinear
                  ? _fromSliderValue(position).clamp(minimum, maximum)
                  : position,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ForceGraphPainter extends CustomPainter {
  _ForceGraphPainter({
    required this.layout,
    required this.geometry,
    required this.viewScale,
    required this.viewTranslation,
    required this.backgroundColor,
    required this.gridColor,
    required this.gridLineWidth,
    required this.nodeSurfaceColor,
    required this.nodeOutlineColor,
    required this.nodeLabelColor,
    required this.edgeColor,
  }) : _edgePaint = Paint()
         ..color = edgeColor
         ..strokeWidth = 1.25
         ..strokeCap = StrokeCap.round,
       _arrowPaint = Paint()..color = edgeColor,
       _surfacePaint = Paint()..color = nodeSurfaceColor,
       _outlinePaint = Paint()
         ..color = nodeOutlineColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.25,
       _gridPaint = Paint()
         ..color = gridColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = gridLineWidth,
       _labels = {
         for (final node in layout.graph.nodes)
           node.id: _createLabel(node.title, nodeLabelColor),
       },
       super(repaint: layout);

  static const _arrowLength = 6.0;
  static const _arrowHalfWidth = 3.0;

  final ForceGraphLayout layout;
  final HexGridGeometry geometry;
  final double viewScale;
  final Offset viewTranslation;
  final Color backgroundColor;
  final Color gridColor;
  final double gridLineWidth;
  final Color nodeSurfaceColor;
  final Color nodeOutlineColor;
  final Color nodeLabelColor;
  final Color edgeColor;
  final Paint _edgePaint;
  final Paint _arrowPaint;
  final Paint _surfacePaint;
  final Paint _outlinePaint;
  final Paint _gridPaint;
  final Map<String, TextPainter> _labels;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(backgroundColor, BlendMode.src);
    HexGridLines.paint(
      canvas: canvas,
      viewportSize: size,
      geometry: geometry,
      screenOrigin: size.center(Offset.zero) + viewTranslation,
      scale: viewScale,
      linePaint: _gridPaint,
    );
    canvas.save();
    canvas.translate(
      size.width / 2 + viewTranslation.dx,
      size.height / 2 + viewTranslation.dy,
    );
    canvas.scale(viewScale);

    for (final edge in layout.graph.edges) {
      if (!layout.isVisible(edge.sourceNodeId) ||
          !layout.isVisible(edge.targetNodeId)) {
        continue;
      }
      _paintDirectedEdge(
        canvas,
        layout.positionOf(edge.sourceNodeId),
        layout.positionOf(edge.targetNodeId),
        _radiusOf(edge.sourceNodeId),
        _radiusOf(edge.targetNodeId),
      );
    }

    for (final node in layout.visibleNodes) {
      final center = layout.positionOf(node.id);
      final nodeRadius = _radiusOf(node.id);
      canvas.drawCircle(center, nodeRadius, _surfacePaint);
      canvas.drawCircle(center, nodeRadius, _outlinePaint);

      final label = _labels[node.id]!;
      label.paint(
        canvas,
        Offset(center.dx - label.width / 2, center.dy + nodeRadius + 3),
      );
    }

    canvas.restore();
  }

  static TextPainter _createLabel(String title, Color color) {
    return TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          fontFamily: NoteverseTypography.fontFamily,
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 10,
        ),
      ),
      maxLines: 1,
      ellipsis: '...',
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 96);
  }

  double _radiusOf(String nodeId) => NoteverseGraphStyle.nodeRadiusFor(
    layout.graph.neighborCountsByNodeId[nodeId]!,
    baseRadius: NoteverseGraphStyle.layoutNodeRadius,
  );

  void _paintDirectedEdge(
    Canvas canvas,
    Offset source,
    Offset target,
    double sourceRadius,
    double targetRadius,
  ) {
    final delta = target - source;
    final distance = delta.distance;
    if (distance <= sourceRadius + targetRadius) {
      return;
    }
    final direction = delta / distance;
    final start = source + direction * sourceRadius;
    final tip = target - direction * targetRadius;
    final arrowLength = math.min(
      _arrowLength,
      (distance - sourceRadius - targetRadius) / 2,
    );
    final base = tip - direction * arrowLength;
    final perpendicular = Offset(-direction.dy, direction.dx);

    canvas.drawLine(start, base, _edgePaint);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(
          base.dx + perpendicular.dx * _arrowHalfWidth,
          base.dy + perpendicular.dy * _arrowHalfWidth,
        )
        ..lineTo(
          base.dx - perpendicular.dx * _arrowHalfWidth,
          base.dy - perpendicular.dy * _arrowHalfWidth,
        )
        ..close(),
      _arrowPaint,
    );
  }

  @override
  bool shouldRepaint(_ForceGraphPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.geometry.radius != geometry.radius ||
      oldDelegate.viewScale != viewScale ||
      oldDelegate.viewTranslation != viewTranslation ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridLineWidth != gridLineWidth ||
      oldDelegate.nodeSurfaceColor != nodeSurfaceColor ||
      oldDelegate.nodeOutlineColor != nodeOutlineColor ||
      oldDelegate.nodeLabelColor != nodeLabelColor ||
      oldDelegate.edgeColor != edgeColor;
}
