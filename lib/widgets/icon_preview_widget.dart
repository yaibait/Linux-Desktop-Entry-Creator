import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconPreviewWidget extends StatelessWidget {
  final String iconPath;
  final String appName;
  final double size;
  final double borderRadius;

  const IconPreviewWidget({
    super.key,
    required this.iconPath,
    required this.appName,
    this.size = 72,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedPath = iconPath.trim();

    Widget content;

    if (trimmedPath.isEmpty) {
      content = _buildPlaceholder(context, theme);
    } else {
      final file = File(trimmedPath);
      if (file.existsSync()) {
        final lower = trimmedPath.toLowerCase();
        if (lower.endsWith('.svg')) {
          content = SvgPicture.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => _buildPlaceholder(context, theme),
          );
        } else {
          content = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildPlaceholder(context, theme),
          );
        }
      } else {
        // Might be a system icon theme name like 'utilities-terminal' or 'applications-games'
        content = _buildPlaceholder(context, theme, subtitle: trimmedPath);
      }
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: content),
    );
  }

  Widget _buildPlaceholder(BuildContext context, ThemeData theme, {String? subtitle}) {
    final initial = appName.trim().isNotEmpty
        ? appName.trim()[0].toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.8),
            theme.colorScheme.tertiary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
