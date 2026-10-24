import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import '../settings/graph_view_settings.dart';

/// Opens graph-view settings and returns the confirmed value.
///
/// Changes are sent to [onPreview] while the dialog is open. A `null` result
/// means that the caller must restore the settings supplied in [initialValue].
Future<GraphViewSettings?> showGraphViewSettingsDialog({
  required BuildContext context,
  required GraphViewSettings initialValue,
  required ValueChanged<GraphViewSettings> onPreview,
}) {
  var draft = initialValue;

  return showDialog<GraphViewSettings>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        void updateBackground(Color color) {
          setDialogState(() {
            draft = draft.copyWith(backgroundColor: color);
          });
          onPreview(draft);
        }

        return AlertDialog(
          title: const Text('Graph view settings'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ColorPicker(
                color: draft.backgroundColor,
                onColorChanged: updateBackground,
                pickersEnabled: const <ColorPickerType, bool>{
                  ColorPickerType.both: false,
                  ColorPickerType.primary: false,
                  ColorPickerType.accent: false,
                  ColorPickerType.bw: false,
                  ColorPickerType.custom: false,
                  ColorPickerType.customSecondary: false,
                  ColorPickerType.wheel: true,
                },
                enableShadesSelection: false,
                enableOpacity: false,
                showColorCode: true,
                colorCodeHasColor: true,
                showEditIconButton: true,
                wheelSubheading: const Text('Background color'),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  updateBackground(GraphViewSettings.defaults.backgroundColor),
              child: const Text('Restore default'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(draft),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}
