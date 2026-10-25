import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'canvas_camera.dart';
import 'data/settings/graph_view_settings_store.dart';
import 'graph/data/graph_asset_loader.dart';
import 'graph/models/graph_data.dart';
import 'hex_grid_geometry.dart';
import 'hex_grid_painter.dart';
import 'settings/graph_view_settings.dart';
import 'theme/noteverse_colors.dart';
import 'theme/noteverse_graph_style.dart';
import 'theme/noteverse_theme.dart';
import 'widgets/canvas_controls.dart';
import 'widgets/canvas_navigation_controls.dart';
import 'widgets/graph_layout_dialog.dart';
import 'widgets/graph_view_settings_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsStore = SharedPreferencesGraphViewSettingsStore();
  final initialSettings = await settingsStore.load();
  final graph = await GraphAssetLoader.load(
    'assets/mock/history_of_computing_graph.json',
  );
  runApp(
    NoteverseApp(
      initialSettings: initialSettings,
      settingsStore: settingsStore,
      graph: graph,
    ),
  );
}

/// Root widget for the Noteverse web application.
class NoteverseApp extends StatelessWidget {
  const NoteverseApp({
    required this.initialSettings,
    required this.settingsStore,
    required this.graph,
    super.key,
  });

  final GraphViewSettings initialSettings;
  final GraphViewSettingsStore settingsStore;
  final GraphData graph;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Noteverse',
    debugShowCheckedModeBanner: false,
    theme: NoteverseTheme.dark,
    home: InfiniteCanvasPage(
      initialSettings: initialSettings,
      settingsStore: settingsStore,
      graph: graph,
    ),
  );
}

/// Displays the pannable Noteverse plane with its origin marker.
class InfiniteCanvasPage extends StatefulWidget {
  const InfiniteCanvasPage({
    required this.initialSettings,
    required this.settingsStore,
    required this.graph,
    super.key,
  });

  final GraphViewSettings initialSettings;
  final GraphViewSettingsStore settingsStore;
  final GraphData graph;

  @override
  State<InfiniteCanvasPage> createState() => _InfiniteCanvasPageState();
}

class _InfiniteCanvasPageState extends State<InfiniteCanvasPage> {
  static const _geometry = HexGridGeometry(radius: 40);

  final CanvasCamera _camera = CanvasCamera(minScale: 1 / 3, maxScale: 4);
  late GraphViewSettings _settings = widget.initialSettings;
  late GraphData _graph = widget.graph;
  double _gestureStartScale = 1;
  Offset _gestureAnchorWorld = Offset.zero;

  Future<void> _openSettings() async {
    final previousSettings = _settings;
    final selectedSettings = await showGraphViewSettingsDialog(
      context: context,
      initialValue: previousSettings,
      onPreview: (settings) {
        if (mounted) {
          setState(() => _settings = settings);
        }
      },
    );

    if (!mounted) {
      return;
    }
    if (selectedSettings == null) {
      setState(() => _settings = previousSettings);
      return;
    }

    setState(() => _settings = selectedSettings);
    try {
      await widget.settingsStore.save(selectedSettings);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save graph view settings.')),
        );
      }
    }
  }

  Future<void> _arrangeGraph() async {
    final arrangedGraph = await showGraphLayoutDialog(
      context: context,
      graph: _graph,
      geometry: _geometry,
      backgroundColor: _settings.backgroundColor,
    );
    if (arrangedGraph != null && mounted) {
      setState(() => _graph = arrangedGraph);
    }
  }

  void _startGesture(ScaleStartDetails details, Size viewportSize) {
    _gestureStartScale = _camera.scale;
    _gestureAnchorWorld = _camera.worldFromScreen(
      details.localFocalPoint,
      viewportSize,
    );
  }

  void _updateGesture(ScaleUpdateDetails details, Size viewportSize) {
    _camera.focusOn(
      anchorWorld: _gestureAnchorWorld,
      focalPoint: details.localFocalPoint,
      viewportSize: viewportSize,
      requestedScale: _gestureStartScale * details.scale,
    );
  }

  void _zoomWithWheel(PointerScrollEvent event, Size viewportSize) {
    final anchorWorld = _camera.worldFromScreen(
      event.localPosition,
      viewportSize,
    );
    final scaleFactor = math.exp(-event.scrollDelta.dy * 0.001);
    _camera.focusOn(
      anchorWorld: anchorWorld,
      focalPoint: event.localPosition,
      viewportSize: viewportSize,
      requestedScale: _camera.scale * scaleFactor,
    );
  }

  void _zoomFromCenter(double factor, Size viewportSize) {
    final focalPoint = viewportSize.center(Offset.zero);
    _camera.focusOn(
      anchorWorld: _camera.worldFromScreen(focalPoint, viewportSize),
      focalPoint: focalPoint,
      viewportSize: viewportSize,
      requestedScale: _camera.scale * factor,
    );
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NoteverseColors.of(context);
    final viewportSize = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final viewportSize = constraints.biggest;
              return MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _zoomWithWheel(event, viewportSize);
                    }
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: (details) =>
                        _startGesture(details, viewportSize),
                    onScaleUpdate: (details) =>
                        _updateGesture(details, viewportSize),
                    child: RepaintBoundary(
                      child: Semantics(
                        label: 'Infinite hexagonal graph plane',
                        child: CustomPaint(
                          painter: HexGridPainter(
                            camera: _camera,
                            geometry: _geometry,
                            graph: _graph,
                            backgroundColor: _settings.backgroundColor,
                            gridColor: colors.graphGridLines,
                            gridLineWidth: NoteverseGraphStyle.gridLineWidth,
                            originColor: colors.graphOrigin,
                            nodeSurfaceColor: colors.graphNodeSurface,
                            nodeOutlineColor: colors.graphNodeOutline,
                            nodeLabelColor: colors.graphNodeLabel,
                            edgeColor: colors.graphEdge,
                          ),
                          size: viewportSize,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 24,
            left: 24,
            child: CanvasControls(onOpenSettings: _openSettings),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: CanvasNavigationControls(
              onZoomOut: () => _zoomFromCenter(0.8, viewportSize),
              onCenter: _camera.centerOnOrigin,
              onZoomIn: () => _zoomFromCenter(1.25, viewportSize),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'arrange-graph',
              onPressed: _arrangeGraph,
              tooltip: 'Arrange graph',
              child: const Icon(Icons.auto_awesome_motion_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
