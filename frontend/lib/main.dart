import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'canvas_camera.dart';
import 'data/settings/graph_view_settings_store.dart';
import 'graph/data/graph_asset_loader.dart';
import 'graph/interaction/graph_hover_controller.dart';
import 'graph/interaction/graph_node_motion.dart';
import 'graph/models/graph_data.dart';
import 'graph/models/graph_node.dart';
import 'graph/models/graph_view_mode.dart';
import 'hex_grid_geometry.dart';
import 'hex_coordinate.dart';
import 'hex_grid_painter.dart';
import 'settings/graph_view_settings.dart';
import 'theme/noteverse_colors.dart';
import 'theme/noteverse_graph_style.dart';
import 'theme/noteverse_theme.dart';
import 'widgets/canvas_controls.dart';
import 'widgets/canvas_mouse_region.dart';
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
    with TickerProviderStateMixin {
  static const _geometry = HexGridGeometry(radius: 40);

  final CanvasCamera _camera = CanvasCamera(minScale: 1 / 3, maxScale: 4);
  late final GraphHoverController _hover = GraphHoverController(vsync: this);
  late final GraphNodeMotion _nodeMotion = GraphNodeMotion(vsync: this);
  Offset? _pointerPosition;
  Size? _pointerViewportSize;
  bool _isDragging = false;
  int _gestureButtons = 0;
  String? _pressedNodeId;
  Offset? _pressWorldPosition;
  Offset? _pressScreenPosition;
  bool _pressStartsBoxSelection = false;
  Rect? _selectionRect;
  Size? _selectionViewportSize;
  bool _draggingNodes = false;
  Map<String, HexCoordinate> _dragCells = const {};
  bool _dragDestinationValid = true;
  late GraphViewSettings _settings = widget.initialSettings;
  late GraphData _graph = widget.graph;
  GraphViewMode _viewMode = GraphViewMode.navigate;
  String? _lastViewedNodeId;
  String? _displayedNodeId;
  Set<String> _editSelectedNodeIds = const {};
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
    if (_viewMode == GraphViewMode.edit &&
        _gestureButtons == kPrimaryButton &&
        details.pointerCount == 1 &&
        _pressStartsBoxSelection) {
      setState(() {
        _selectionRect = Rect.fromPoints(
          _pressScreenPosition!,
          details.localFocalPoint,
        );
        _selectionViewportSize = viewportSize;
      });
    }
    _draggingNodes =
        _viewMode == GraphViewMode.edit &&
        _gestureButtons == kPrimaryButton &&
        details.pointerCount == 1 &&
        _pressedNodeId != null &&
        _editSelectedNodeIds.contains(_pressedNodeId);
    if (_draggingNodes) {
      _nodeMotion.finish();
    }
    _lastEditTapNodeId = null;
    _setHoveredNode(null);
    _gestureStartScale = _camera.scale;
    _gestureAnchorWorld = _camera.worldFromScreen(
      details.localFocalPoint,
      viewportSize,
    );
  }

  void _updateGesture(ScaleUpdateDetails details, Size viewportSize) {
    _pointerPosition = details.localFocalPoint;
    if (_selectionRect != null) {
      setState(() {
        _selectionRect = Rect.fromPoints(
          _pressScreenPosition!,
          details.localFocalPoint,
        );
      });
      return;
    }
    if (_draggingNodes) {
      final position = _camera.worldFromScreen(
        details.localFocalPoint,
        viewportSize,
      );
      final displacement = position - _pressWorldPosition!;
      _nodeMotion.follow({
        for (final id in _editSelectedNodeIds)
          id: _geometry.centerOf(_graph.nodesById[id]!.cell) + displacement,
      });
      // Round the displacement, not the pointer's absolute cell, so grabbing
      // anywhere inside a selected hexagon preserves the group's arrangement.
      final delta = _geometry.coordinateAt(displacement);
      final cells = {
        for (final id in _editSelectedNodeIds)
          id: HexCoordinate(
            _graph.nodesById[id]!.cell.q + delta.q,
            _graph.nodesById[id]!.cell.r + delta.r,
          ),
      };
      if (_dragCells.isNotEmpty &&
          _dragCells[_pressedNodeId] == cells[_pressedNodeId]) {
        return;
      }
      final valid = cells.values.every((cell) {
        final occupant = _graph.nodeIdByCell[cell];
        return occupant == null || _editSelectedNodeIds.contains(occupant);
      });
      setState(() {
        _dragCells = cells;
        _dragDestinationValid = valid;
      });
      return;
    }
    if (_gestureButtons == kSecondaryButton) {
      _camera.focusOn(
        anchorWorld: _gestureAnchorWorld,
        focalPoint: details.localFocalPoint,
        viewportSize: viewportSize,
        requestedScale: _gestureStartScale * details.scale,
      );
    }
  }

  /// Commits a box selection or group translation, unless cancelled.
  void _endGesture({bool cancelled = false}) {
    final movingNodeIds = _draggingNodes
        ? _nodeMotion.positions.keys.toList(growable: false)
        : const <String>[];
    setState(() {
      final selectionRect = _selectionRect;
      if (!cancelled && selectionRect != null) {
        final worldBounds = Rect.fromPoints(
          _camera.worldFromScreen(
            selectionRect.topLeft,
            _selectionViewportSize!,
          ),
          _camera.worldFromScreen(
            selectionRect.bottomRight,
            _selectionViewportSize!,
          ),
        );
        // Test the cell centers in world space, independently of zoom, hover
        // elevation, and node size. Include centers on the rectangle's edges.
        _editSelectedNodeIds = {
          ..._editSelectedNodeIds,
          for (final node in _graph.nodes)
            if (_geometry.centerOf(node.cell) case final center
                when center.dx >= worldBounds.left &&
                    center.dx <= worldBounds.right &&
                    center.dy >= worldBounds.top &&
                    center.dy <= worldBounds.bottom)
              node.id,
        };
      }
      if (_draggingNodes &&
          !cancelled &&
          _dragDestinationValid &&
          _dragCells.isNotEmpty) {
        _graph = GraphData(
          graphId: _graph.graphId,
          nodes: [
            for (final node in _graph.nodes)
              if (_dragCells[node.id] case final cell?)
                GraphNode(
                  id: node.id,
                  title: node.title,
                  sourcePath: node.sourcePath,
                  cell: cell,
                  markdownContent: node.markdownContent,
                )
              else
                node,
          ],
          edges: _graph.edges,
        );
      }
      _dragCells = const {};
      _dragDestinationValid = true;
      _draggingNodes = false;
      _isDragging = false;
      _gestureButtons = 0;
      _pressedNodeId = null;
      _pressWorldPosition = null;
      _pressScreenPosition = null;
      _pressStartsBoxSelection = false;
      _selectionRect = null;
      _selectionViewportSize = null;
    });
    if (movingNodeIds.isNotEmpty) {
      _nodeMotion.settle({
        for (final id in movingNodeIds)
          id: _geometry.centerOf(_graph.nodesById[id]!.cell),
      }, animate: !MediaQuery.disableAnimationsOf(context));
    }
    _refreshHover();
  }

  void _zoomWithWheel(PointerScrollEvent event, Size viewportSize) {
    if (_draggingNodes || _selectionRect != null) {
      return;
    }
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
        _editSelectedNodeIds = {nodeId};
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
    if (HardwareKeyboard.instance.isControlPressed) {
      // Modified clicks toggle selection and never open a note on a double tap.
      _lastEditTapNodeId = null;
      if (nodeId != null) {
        final selected = {..._editSelectedNodeIds};
        if (!selected.remove(nodeId)) {
          selected.add(nodeId);
        }
        setState(() => _editSelectedNodeIds = selected);
      }
      return;
    }
    final opensNote =
        details.count.isEven && nodeId != null && nodeId == _lastEditTapNodeId;
    _lastEditTapNodeId = nodeId;
    if (nodeId == null) {
      if (_editSelectedNodeIds.isNotEmpty) {
        setState(() => _editSelectedNodeIds = const {});
      }
      return;
    }
    if (opensNote) {
      _showNodePreview(nodeId);
    } else if (_editSelectedNodeIds.length != 1 ||
        !_editSelectedNodeIds.contains(nodeId)) {
      setState(() => _editSelectedNodeIds = {nodeId});
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
    _nodeMotion.dispose();
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
                  return CanvasMouseRegion(
                    cursor: _selectionRect != null
                        ? SystemMouseCursors.precise
                        : _hover.hoveredNodeId != null &&
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
                      onPointerDown: (event) {
                        if (!_isDragging) {
                          _gestureButtons = event.buttons;
                        }
                        if (!_isDragging && event.buttons == kPrimaryButton) {
                          _pressedNodeId = _nodeAt(
                            event.localPosition,
                            viewportSize,
                          );
                          _pressWorldPosition = _camera.worldFromScreen(
                            event.localPosition,
                            viewportSize,
                          );
                          _pressScreenPosition = event.localPosition;
                          _pressStartsBoxSelection =
                              _viewMode == GraphViewMode.edit &&
                              _pressedNodeId == null &&
                              HardwareKeyboard.instance.isControlPressed;
                        }
                      },
                      onPointerCancel: (_) => _endGesture(cancelled: true),
                      onPointerSignal: (event) {
                        if (event is PointerScrollEvent) {
                          _zoomWithWheel(event, viewportSize);
                        }
                      },
                      child: RawGestureDetector(
                        behavior: HitTestBehavior.opaque,
                        gestures: {
                          ScaleGestureRecognizer:
                              GestureRecognizerFactoryWithHandlers<
                                ScaleGestureRecognizer
                              >(
                                () => ScaleGestureRecognizer(
                                  allowedButtonsFilter: (buttons) =>
                                      buttons == kSecondaryButton ||
                                      (buttons == kPrimaryButton &&
                                          _viewMode == GraphViewMode.edit),
                                ),
                                (recognizer) {
                                  recognizer.onStart = (details) =>
                                      _startGesture(details, viewportSize);
                                  recognizer.onUpdate = (details) =>
                                      _updateGesture(details, viewportSize);
                                  recognizer.onEnd = (_) => _endGesture();
                                },
                              ),
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
                          child: RepaintBoundary(
                            child: Semantics(
                              label: 'Infinite hexagonal graph plane',
                              child: CustomPaint(
                                painter: HexGridPainter(
                                  camera: _camera,
                                  hover: _hover,
                                  nodeMotion: _nodeMotion,
                                  geometry: _geometry,
                                  graph: _graph,
                                  selectionRect: _selectionRect,
                                  previewCells: _dragCells,
                                  invalidPreview: !_dragDestinationValid,
                                  invalidNodeColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
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
                                  selectedNodeIds:
                                      _viewMode == GraphViewMode.edit
                                      ? _editSelectedNodeIds
                                      : {
                                          if (_previewOpen &&
                                              _lastViewedNodeId != null)
                                            _lastViewedNodeId!,
                                        },
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
