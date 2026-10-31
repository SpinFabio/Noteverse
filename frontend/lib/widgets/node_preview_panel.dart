import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../graph/models/graph_node.dart';
import '../theme/noteverse_markdown_style.dart';

/// Floating note preview; closing it is managed separately from its content.
class NodePreviewPanel extends StatelessWidget {
  const NodePreviewPanel({
    required this.node,
    required this.onClose,
    required this.onOpenLink,
    super.key,
  });

  final GraphNode node;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  node.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close note preview',
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey('note-preview-${node.id}'),
            padding: const EdgeInsets.all(20),
            child: MarkdownBody(
              data: node.markdownContent.isEmpty
                  ? 'No note content available.'
                  : node.markdownContent,
              selectable: true,
              styleSheet: NoteverseMarkdownStyle.of(context),
              onTapLink: (text, href, title) {
                if (href != null) {
                  onOpenLink(href);
                }
              },
            ),
          ),
        ),
      ],
    ),
  );
}
