import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// Markdown presentation derived from the application's typography and colors.
abstract final class NoteverseMarkdownStyle {
  static MarkdownStyleSheet of(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colors = theme.colorScheme;
    return MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: text.bodyMedium?.copyWith(height: 1.6),
      h1: text.headlineSmall,
      h2: text.titleLarge,
      h3: text.titleMedium,
      h4: text.titleSmall,
      h5: text.titleSmall,
      h6: text.titleSmall,
      a: text.bodyMedium?.copyWith(
        color: colors.tertiary,
        decoration: TextDecoration.underline,
        decorationColor: colors.tertiary,
      ),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      code: text.bodySmall?.copyWith(
        backgroundColor: colors.surfaceContainerHighest,
      ),
      blockSpacing: 14,
      h1Padding: const EdgeInsets.only(top: 8, bottom: 8),
      h2Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 6, bottom: 4),
      listIndent: 20,
      blockquotePadding: const EdgeInsets.all(12),
      blockquoteDecoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(left: BorderSide(color: colors.outline, width: 3)),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
