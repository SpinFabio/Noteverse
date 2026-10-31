import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Suppresses the web context menu over a canvas, including right-button drags.
///
/// Flutter's browser switch is global. Shared ownership and serialized updates
/// keep overlapping canvas regions from restoring it while another needs it.
class CanvasMouseRegion extends StatefulWidget {
  const CanvasMouseRegion({
    required this.child,
    this.cursor = MouseCursor.defer,
    this.onEnter,
    this.onHover,
    this.onExit,
    super.key,
  });

  final Widget child;
  final MouseCursor cursor;
  final PointerEnterEventListener? onEnter;
  final PointerHoverEventListener? onHover;
  final PointerExitEventListener? onExit;

  @override
  State<CanvasMouseRegion> createState() => _CanvasMouseRegionState();
}

class _CanvasMouseRegionState extends State<CanvasMouseRegion> {
  static final _owners = <Object>{};
  static Future<void> _pending = Future.value();
  static bool? _restoreEnabled;
  bool _inside = false;
  int? _rightPointer;

  void _syncContextMenu() {
    if (!kIsWeb) return;
    final suppress = _inside || _rightPointer != null;
    if (suppress) {
      if (_owners.contains(this)) return;
      _restoreEnabled ??= BrowserContextMenu.enabled;
      _owners.add(this);
    } else if (!_owners.remove(this)) {
      return;
    }
    _pending = _pending
        .then((_) async {
          if (_owners.isNotEmpty) {
            await BrowserContextMenu.disableContextMenu();
          } else {
            if (_restoreEnabled == true) {
              await BrowserContextMenu.enableContextMenu();
            }
            if (_owners.isEmpty) _restoreEnabled = null;
          }
        })
        .catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(exception: error, stack: stack),
          );
        });
  }

  @override
  void dispose() {
    _inside = false;
    _rightPointer = null;
    _syncContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.cursor,
    onEnter: (event) {
      _inside = true;
      _syncContextMenu();
      widget.onEnter?.call(event);
    },
    onHover: widget.onHover,
    onExit: (event) {
      _inside = false;
      _syncContextMenu();
      widget.onExit?.call(event);
    },
    child: Listener(
      onPointerDown: (event) {
        if (event.buttons == kSecondaryButton) {
          _rightPointer = event.pointer;
          _syncContextMenu();
        }
      },
      onPointerUp: _releasePointer,
      onPointerCancel: _releasePointer,
      child: widget.child,
    ),
  );

  void _releasePointer(PointerEvent event) {
    if (_rightPointer == event.pointer) {
      _rightPointer = null;
      _syncContextMenu();
    }
  }
}
