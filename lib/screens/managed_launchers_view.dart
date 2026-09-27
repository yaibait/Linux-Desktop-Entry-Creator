import 'package:flutter/material.dart';
import '../models/desktop_entry.dart';
import '../services/desktop_entry_service.dart';
import '../widgets/icon_preview_widget.dart';

class ManagedLaunchersView extends StatefulWidget {
  final Function(DesktopEntry entry)? onEditEntry;

  const ManagedLaunchersView({super.key, this.onEditEntry});

  @override
  State<ManagedLaunchersView> createState() => _ManagedLaunchersViewState();
}

class _ManagedLaunchersViewState extends State<ManagedLaunchersView> {
  List<ExistingDesktopEntry> _entries = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final list = await DesktopEntryService.listUserEntries();
    if (mounted) {
      setState(() {
        _entries = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEntry(ExistingDesktopEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Desktop Launcher?'),
        content: Text('Are you sure you want to remove "${entry.name}" from your application menu?\n\nFile: ${entry.filePath}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await DesktopEntryService.deleteEntry(entry.filePath);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${entry.name}" from menu.')),
          );
          _loadEntries();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete file.')),
          );
        }
      }
    }
  }

  void _editEntry(ExistingDesktopEntry entry) {
    final categories = entry.categories
        .split(';')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final primaryCategory = categories.isNotEmpty ? categories.first : 'Utility';
    final additional = categories.length > 1 ? categories.sublist(1) : <String>[];

    final desktopEntry = DesktopEntry(
      name: entry.name,
      execPath: entry.exec,
      iconPath: entry.icon,
      category: primaryCategory,
      additionalCategories: additional,
      comment: entry.comment,
      workingDirectory: entry.workingDirectory,
      terminal: entry.terminal,
      customFileName: entry.fileName,
    );

    widget.onEditEntry?.call(desktopEntry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _entries.where((e) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
          e.exec.toLowerCase().contains(query) ||
          e.fileName.toLowerCase().contains(query) ||
          e.categories.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Installed Standalone Applications',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Applications located in ~/.local/share/applications',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: DesktopEntryService.openApplicationsFolder,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Open Folder'),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Refresh list',
                icon: const Icon(Icons.refresh),
                onPressed: _loadEntries,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search installed applications...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),

          const SizedBox(height: 16),

          // Entry list or empty state
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No custom applications found yet'
                                  : 'No applications match "$_searchQuery"',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use "Create Launcher" to add your first standalone app or AppImage.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  IconPreviewWidget(
                                    iconPath: item.icon,
                                    appName: item.name,
                                    size: 52,
                                    borderRadius: 12,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.name,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.fileName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.exec,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: theme.colorScheme.secondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.comment.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            item.comment,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton.filledTonal(
                                        tooltip: 'Launch application',
                                        icon: const Icon(Icons.play_arrow, size: 20),
                                        onPressed: () {
                                          DesktopEntryService.launchApp(
                                            item.exec,
                                            workingDirectory: item.workingDirectory,
                                            terminal: item.terminal,
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton.outlined(
                                        tooltip: 'Load into editor',
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        onPressed: () => _editEntry(item),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton.outlined(
                                        tooltip: 'Delete launcher',
                                        icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                                        onPressed: () => _deleteEntry(item),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
