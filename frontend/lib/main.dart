import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'canvas_camera.dart';
import 'data/settings/graph_view_settings_store.dart';
import 'graph/data/graph_asset_loader.dart';
import 'graph/interaction/graph_hover_controller.dart';
import 'graph/models/graph_data.dart';
import 'graph/models/graph_node.dart';
import 'graph/models/graph_view_mode.dart';
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
import 'widgets/graph_view_mode_controls.dart';
import 'widgets/node_preview_panel.dart';

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

class _InfiniteCanvasPageState extends State<InfiniteCanvasPage>
    with SingleTickerProviderStateMixin {
  static const _geometry = HexGridGeometry(radius: 40);

  final CanvasCamera _camera = CanvasCamera(minScale: 1 / 3, maxScale: 4);
  late final GraphHoverController _hover = GraphHoverController(vsync: this);
  Offset? _pointerPosition;
  Size? _pointerViewportSize;
  bool _isDragging = false;
  late GraphViewSettings _settings = widget.initialSettings;
  late GraphData _graph = widget.graph;
  GraphViewMode _viewMode = GraphViewMode.navigate;
  String? _lastViewedNodeId;
  String? _displayedNodeId;
  String? _editSelectedNodeId;
  bool _previewOpen = false;
  bool _previewExiting = false;
  String? _lastEditTapNodeId;
  double _gestureStartScale = 1;
  Offset _gestureAnchorWorld = Offset.zero;

  @override
  void initState() {
    super.initState();
    _camera.addListener(_refreshHover);
  }

  /// Shared hit detection for hover, selection, and opening notes.
  ///
  /// The entire occupied cell stays interactive while its node visually lifts.
  String? _nodeAt(Offset screenPosition, Size viewportSize) {
    final worldPosition = _camera.worldFromScreen(screenPosition, viewportSize);
    return _graph.nodeIdByCell[_geometry.coordinateAt(worldPosition)];
  }

  void _setHoveredNode(String? nodeId) {
    if (_hover.hoveredNodeId == nodeId) {
      return;
    }
    _hover.setHoveredNode(
      nodeId,
      animate: !MediaQuery.disableAnimationsOf(context),
    );
    setState(() {});
  }

  void _refreshHover() {
    final pointer = _pointerPosition;
    final size = _pointerViewportSize;
    _setHoveredNode(
      _viewMode != GraphViewMode.navigate &&
              !_isDragging &&
              pointer != null &&
              size != null
          ? _nodeAt(pointer, size)
          : null,
    );
  }

  void _trackPointer(Offset position, Size viewportSize) {
    _pointerPosition = position;
    _pointerViewportSize = viewportSize;
    _refreshHover();
  }

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
    _isDragging = true;
    _setHoveredNode(null);
    _gestureStartScale = _camera.scale;
    _gestureAnchorWorld = _camera.worldFromScreen(
      details.localFocalPoint,
      viewportSize,
    );
  }

  void _updateGesture(ScaleUpdateDetails details, Size viewportSize) {
    _pointerPosition = details.localFocalPoint;
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

  void _openNodeAt(Offset screenPosition, Size viewportSize) {
    final nodeId = _nodeAt(screenPosition, viewportSize);
    if (nodeId == null) {
      return;
    }
    _showNodePreview(nodeId);
  }

  void _showNodePreview(String nodeId) {
    setState(() {
      if (_viewMode == GraphViewMode.edit) {
        _editSelectedNodeId = nodeId;
      }
      _lastViewedNodeId = nodeId;
      final shouldTransition =
          _previewOpen &&
          _displayedNodeId != nodeId &&
          !MediaQuery.disableAnimationsOf(context);
      _previewExiting = shouldTransition;
      if (!shouldTransition) {
        _displayedNodeId = nodeId;
      }
      _previewOpen = true;
    });
  }

  /// Responds to each completed edit tap without waiting for a double-tap timeout.
  void _handleEditTap(SerialTapUpDetails details, Size viewportSize) {
    final nodeId = _nodeAt(details.localPosition, viewportSize);
    final opensNote =
        details.count.isEven && nodeId != null && nodeId == _lastEditTapNodeId;
    _lastEditTapNodeId = nodeId;
    if (nodeId == null) {
      return;
    }
    if (opensNote) {
      _showNodePreview(nodeId);
    } else if (_editSelectedNodeId != nodeId) {
      setState(() => _editSelectedNodeId = nodeId);
    }
  }

  void _closeNodePreview() {
    setState(() {
      _previewOpen = false;
      _previewExiting = false;
    });
  }

  /// Resolves Markdown note paths relative to the note containing the link.
  Future<void> _openNoteLink(GraphNode source, String href) async {
    final link = Uri.tryParse(href);
    if (link == null) {
      _showLinkError('Invalid link.');
      return;
    }
    if (link.hasScheme || link.hasAuthority) {
      final external = link.hasScheme ? link : link.replace(scheme: 'https');
      if (external.scheme != 'http' && external.scheme != 'https') {
        _showLinkError('This link type is not supported.');
        return;
      }
      try {
        final opened = await launchUrl(external, webOnlyWindowName: '_blank');
        if (!opened && mounted) {
          _showLinkError('Unable to open the link in the browser.');
        }
      } on Object {
        if (mounted) {
          _showLinkError('Unable to open the link in the browser.');
        }
      }
      return;
    }

    final target = Uri(
      path: '/${source.sourcePath}',
    ).resolveUri(link).normalizePath();
    for (final node in _graph.nodes) {
      if (Uri(path: '/${node.sourcePath}').normalizePath().path ==
          target.path) {
        _showNodePreview(node.id);
        return;
      }
    }
    _showLinkError('The linked note is not available in this graph.');
  }

  void _showLinkError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _finishPreviewTransition() {
    if (_previewExiting && _previewOpen) {
      setState(() {
        // Use the latest request even if another node was clicked during exit.
        _displayedNodeId = _lastViewedNodeId;
        _previewExiting = false;
      });
    }
  }

  @override
  void dispose() {
    _camera.removeListener(_refreshHover);
    _hover.dispose();
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = NoteverseColors.of(context);
    final viewportSize = MediaQuery.sizeOf(context);
    final lastViewedNode = _graph.nodesById[_lastViewedNodeId];
    final displayedNode = _graph.nodesById[_displayedNodeId];
    final previewWidth = math.min(
      viewportSize.width - 32,
      (viewportSize.width * 0.35).clamp(320.0, 480.0),
    );
    return CallbackShortcuts(
      bindings: {
        if (_viewMode == GraphViewMode.explore && _previewOpen)
          const SingleActivator(LogicalKeyboardKey.escape): _closeNodePreview,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final viewportSize = constraints.biggest;
                  return MouseRegion(
                    cursor:
                        _hover.hoveredNodeId != null &&
                            _viewMode != GraphViewMode.navigate
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.grab,
                    onEnter: (event) =>
                        _trackPointer(event.localPosition, viewportSize),
                    onHover: (event) =>
                        _trackPointer(event.localPosition, viewportSize),
                    onExit: (_) {
                      _pointerPosition = null;
                      _setHoveredNode(null);
                    },
                    child: Listener(
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          _zoomWithWheel(event, viewportSize);
                        }
                      },
                      child: RawGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        gestures: {
                          if (_viewMode == GraphViewMode.edit)
                            SerialTapGestureRecognizer:
                                GestureRecognizerFactoryWithHandlers<
                                  SerialTapGestureRecognizer
                                >(
                                  () => SerialTapGestureRecognizer(
                                    allowedButtonsFilter: (buttons) =>
                                        buttons == kPrimaryButton,
                                  ),
                                  (recognizer) {
                                    recognizer.onSerialTapUp = (details) =>
                                        _handleEditTap(details, viewportSize);
                                  },
                                ),
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: _viewMode == GraphViewMode.explore
                              ? (details) => _openNodeAt(
                                  details.localPosition,
                                  viewportSize,
                                )
                              : null,
                          onScaleStart: (details) =>
                              _startGesture(details, viewportSize),
                          onScaleUpdate: (details) =>
                              _updateGesture(details, viewportSize),
                          onScaleEnd: (_) {
                            _isDragging = false;
                            _refreshHover();
                          },
                          child: RepaintBoundary(
                            child: Semantics(
                              label: 'Infinite hexagonal graph plane',
                              child: CustomPaint(
                                painter: HexGridPainter(
                                  camera: _camera,
                                  hover: _hover,
                                  geometry: _geometry,
                                  graph: _graph,
                                  backgroundColor: _settings.backgroundColor,
                                  gridColor: colors.graphGridLines,
                                  gridLineWidth:
                                      NoteverseGraphStyle.gridLineWidth,
                                  originColor: colors.graphOrigin,
                                  nodeSurfaceColor: colors.graphNodeSurface,
                                  nodeOutlineColor: colors.graphNodeOutline,
                                  nodeLabelColor: colors.graphNodeLabel,
                                  edgeColor: colors.graphEdge,
                                  nodeHoverColor: Theme.of(
                                    context,
                                  ).colorScheme.tertiary,
                                  shadowColor: Theme.of(
                                    context,
                                  ).colorScheme.shadow,
                                  selectedNodeId:
                                      _viewMode == GraphViewMode.edit
                                      ? _editSelectedNodeId
                                      : (_previewOpen
                                            ? _lastViewedNodeId
                                            : null),
                                ),
                                size: viewportSize,
                              ),
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
                top: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: GraphViewModeControls(
                    mode: _viewMode,
                    onChanged: (mode) {
                      setState(() {
                        _viewMode = mode;
                        _lastEditTapNodeId = null;
                      });
                      _refreshHover();
                    },
                  ),
                ),
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
              if (_viewMode == GraphViewMode.edit)
                Positioned(
                  right: _previewOpen ? previewWidth + 32 : 24,
                  bottom: 24,
                  child: FloatingActionButton.small(
                    heroTag: 'arrange-graph',
                    onPressed: _arrangeGraph,
                    tooltip: 'Arrange graph',
                    child: const Icon(Icons.auto_awesome_motion_outlined),
                  ),
                ),
              if (!_previewOpen)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Material(
                    color: colors.floatingControlSurface,
                    elevation: 6,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Reopen last note',
                      onPressed: lastViewedNode == null
                          ? null
                          : () => _showNodePreview(lastViewedNode.id),
                      icon: const Icon(Icons.article_outlined),
                    ),
                  ),
                ),
              Positioned(
                right: 16,
                top: viewportSize.height * 0.05,
                bottom: viewportSize.height * 0.05,
                width: previewWidth,
                child: IgnorePointer(
                  ignoring: !_previewOpen || _previewExiting,
                  child: ExcludeSemantics(
                    excluding: !_previewOpen || _previewExiting,
                    child: AnimatedSlide(
                      offset: _previewOpen && !_previewExiting
                          ? Offset.zero
                          : const Offset(1.1, 0),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      onEnd: _finishPreviewTransition,
                      child: displayedNode == null
                          ? const SizedBox.shrink()
                          : NodePreviewPanel(
                              node: displayedNode,
                              onClose: _closeNodePreview,
                              onOpenLink: (href) =>
                                  _openNoteLink(displayedNode, href),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
