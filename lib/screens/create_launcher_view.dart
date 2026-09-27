import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/desktop_entry.dart';
import '../services/desktop_entry_service.dart';
import '../services/file_picker_service.dart';
import '../widgets/desktop_preview_card.dart';

class CreateLauncherView extends StatefulWidget {
  final DesktopEntry? initialEntry;
  final VoidCallback? onCreated;

  const CreateLauncherView({
    super.key,
    this.initialEntry,
    this.onCreated,
  });

  @override
  State<CreateLauncherView> createState() => _CreateLauncherViewState();
}

class _CreateLauncherViewState extends State<CreateLauncherView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _execController;
  late TextEditingController _iconController;
  late TextEditingController _commentController;
  late TextEditingController _genericNameController;
  late TextEditingController _workDirController;
  late TextEditingController _wmClassController;
  late TextEditingController _customFileNameController;

  String _selectedCategory = 'Utility';
  final List<String> _additionalCategories = [];
  bool _terminal = false;
  bool _makeExecutable = true;
  bool _copyIcon = true;
  bool _addNoSandbox = false;
  bool _showAdvanced = false;
  bool _isLoading = false;

  final List<String> _standardCategories = [
    'Utility',
    'Development',
    'Game',
    'Graphics',
    'AudioVideo',
    'Network',
    'Office',
    'System',
    'Settings',
    'Education',
    'Science',
  ];

  final List<String> _commonSubCategories = [
    'TextEditor',
    'IDE',
    'WebBrowser',
    'Email',
    'Player',
    'Recorder',
    'Emulator',
    'FileTools',
    'VectorGraphics',
    '2DGraphics',
    '3DGraphics',
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry ?? DesktopEntry();
    _nameController = TextEditingController(text: entry.name);
    _execController = TextEditingController(text: entry.execPath);
    _iconController = TextEditingController(text: entry.iconPath);
    _commentController = TextEditingController(text: entry.comment);
    _genericNameController = TextEditingController(text: entry.genericName);
    _workDirController = TextEditingController(text: entry.workingDirectory);
    _wmClassController = TextEditingController(text: entry.startupWmClass);
    _customFileNameController = TextEditingController(text: entry.customFileName);
    _selectedCategory = entry.category.isNotEmpty ? entry.category : 'Utility';
    _terminal = entry.terminal;
    _makeExecutable = entry.makeExecutable;
    _copyIcon = entry.copyIcon;
    _addNoSandbox = entry.addNoSandbox;

    _nameController.addListener(_onFieldChanged);
    _execController.addListener(_onFieldChanged);
    _iconController.addListener(_onFieldChanged);
    _commentController.addListener(_onFieldChanged);
    _genericNameController.addListener(_onFieldChanged);
    _workDirController.addListener(_onFieldChanged);
    _wmClassController.addListener(_onFieldChanged);
    _customFileNameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _execController.dispose();
    _iconController.dispose();
    _commentController.dispose();
    _genericNameController.dispose();
    _workDirController.dispose();
    _wmClassController.dispose();
    _customFileNameController.dispose();
    super.dispose();
  }

  DesktopEntry _getCurrentEntry() {
    return DesktopEntry(
      name: _nameController.text,
      execPath: _execController.text,
      iconPath: _iconController.text,
      category: _selectedCategory,
      additionalCategories: _additionalCategories,
      comment: _commentController.text,
      genericName: _genericNameController.text,
      workingDirectory: _workDirController.text,
      terminal: _terminal,
      startupWmClass: _wmClassController.text,
      makeExecutable: _makeExecutable,
      copyIcon: _copyIcon,
      addNoSandbox: _addNoSandbox,
      customFileName: _customFileNameController.text,
    );
  }

  Future<void> _pickExecutable() async {
    final path = await FilePickerService.pickExecutable();
    if (path != null && mounted) {
      _execController.text = path;

      // Auto-populate name if empty
      if (_nameController.text.trim().isEmpty) {
        String baseName = p.basenameWithoutExtension(path);
        // Clean common prefixes or suffixes
        baseName = baseName.replaceAll(RegExp(r'[-_]'), ' ');
        if (baseName.isNotEmpty) {
          _nameController.text = baseName[0].toUpperCase() + baseName.substring(1);
        }
      }

      // Auto-fill working directory if empty
      if (_workDirController.text.trim().isEmpty) {
        _workDirController.text = p.dirname(path);
      }

      // If no icon yet, try to auto-detect icon in the same directory
      if (_iconController.text.trim().isEmpty) {
        _tryAutoDetectIcon(p.dirname(path), p.basenameWithoutExtension(path));
      }
    }
  }

  void _tryAutoDetectIcon(String dirPath, String appSlug) {
    try {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        final files = dir.listSync();
        for (final f in files) {
          if (f is File) {
            final ext = p.extension(f.path).toLowerCase();
            if (['.png', '.svg', '.ico'].contains(ext)) {
              final fname = p.basenameWithoutExtension(f.path).toLowerCase();
              if (fname.contains('icon') || fname.contains(appSlug.toLowerCase())) {
                _iconController.text = f.path;
                break;
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _pickIcon() async {
    final path = await FilePickerService.pickIcon();
    if (path != null && mounted) {
      _iconController.text = path;
    }
  }

  Future<void> _pickWorkingDir() async {
    final path = await FilePickerService.pickDirectory(
      initialDirectory: _workDirController.text.isNotEmpty ? _workDirController.text : null,
    );
    if (path != null && mounted) {
      _workDirController.text = path;
    }
  }

  Future<void> _handleAddToMenu() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final entry = _getCurrentEntry();
    final result = await DesktopEntryService.addToMenu(entry);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      widget.onCreated?.call();
      _showSuccessDialog(result, entry);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog(DesktopEntryResult result, DesktopEntry entry) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF26A269), size: 28),
            const SizedBox(width: 10),
            const Text('Added to Application Menu!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desktop launcher for "${entry.name}" has been created and registered with your desktop environment.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Installed file:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    result.desktopFilePath ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              DesktopEntryService.openApplicationsFolder();
            },
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open Folder'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF26A269)),
            onPressed: () {
              Navigator.pop(ctx);
              DesktopEntryService.launchApp(
                entry.execPath,
                workingDirectory: entry.workingDirectory,
                terminal: entry.terminal,
              );
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Test Run Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _execController.clear();
    _iconController.clear();
    _commentController.clear();
    _genericNameController.clear();
    _workDirController.clear();
    _wmClassController.clear();
    _customFileNameController.clear();
    setState(() {
      _selectedCategory = 'Utility';
      _additionalCategories.clear();
      _terminal = false;
      _makeExecutable = true;
      _copyIcon = true;
      _addNoSandbox = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = _getCurrentEntry();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final formContent = Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                context,
                title: 'Application Details',
                icon: Icons.app_registration,
                description: 'Fill in the basic info for your Linux application launcher.',
              ),
              const SizedBox(height: 16),

              // 1. Application Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Application Name *',
                  hintText: 'e.g. Cursor, Obsidian, Blender 4.2',
                  prefixIcon: const Icon(Icons.label_outline),
                  helperText: 'The name that appears in your OS application launcher',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Application Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Application Path (Executable)
              TextFormField(
                controller: _execController,
                decoration: InputDecoration(
                  labelText: 'Application Path (Executable) *',
                  hintText: '/home/user/Applications/myapp.AppImage',
                  prefixIcon: const Icon(Icons.code_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickExecutable,
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Browse'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  helperText: 'Select an AppImage, Linux binary, or shell script (.sh)',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Application Path is required';
                  }
                  final f = File(val.trim());
                  if (!f.existsSync()) {
                    return 'Executable file does not exist on disk';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),
              // Option: make executable
              CheckboxListTile(
                value: _makeExecutable,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Automatically make file executable (chmod +x)'),
                subtitle: const Text('Essential for newly downloaded AppImages and shell scripts'),
                onChanged: (val) {
                  setState(() => _makeExecutable = val ?? true);
                },
              ),

              const SizedBox(height: 14),

              // 3. Application Icon
              TextFormField(
                controller: _iconController,
                decoration: InputDecoration(
                  labelText: 'Application Icon',
                  hintText: '/path/to/icon.png or system icon name',
                  prefixIcon: const Icon(Icons.image_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickIcon,
                        icon: const Icon(Icons.image_search, size: 16),
                        label: const Text('Browse'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  helperText: 'Supports PNG, SVG, ICO, JPG, WebP, or system icon names',
                ),
              ),

              const SizedBox(height: 8),
              // Option: copy icon to ~/.local/share/icons
              CheckboxListTile(
                value: _copyIcon,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Copy icon to ~/.local/share/icons/'),
                subtitle: const Text('Keeps the icon safe even if original download folder is moved or deleted'),
                onChanged: (val) {
                  setState(() => _copyIcon = val ?? true);
                },
              ),

              const SizedBox(height: 18),

              // 4. Application Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Application Category *',
                        prefixIcon: Icon(Icons.category_outlined),
                        helperText: 'Main category in Linux application menu',
                      ),
                      items: _standardCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Optional Secondary Tags
              Text(
                'Secondary Tags (Optional):',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _commonSubCategories.map((sub) {
                  final isSelected = _additionalCategories.contains(sub);
                  return FilterChip(
                    label: Text(sub),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _additionalCategories.add(sub);
                        } else {
                          _additionalCategories.remove(sub);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Collapsible Advanced Settings
              Card(
                child: ExpansionTile(
                  initiallyExpanded: _showAdvanced,
                  onExpansionChanged: (exp) => setState(() => _showAdvanced = exp),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                  title: Row(
                    children: [
                      Icon(Icons.tune_outlined, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Advanced Options',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  subtitle: const Text('Working directory, terminal flag, no-sandbox, WM class'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              labelText: 'Comment / Description',
                              hintText: 'e.g. Modern AI-powered code editor',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _genericNameController,
                            decoration: const InputDecoration(
                              labelText: 'Generic Name',
                              hintText: 'e.g. Text Editor, Web Browser',
                              prefixIcon: Icon(Icons.short_text_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _workDirController,
                            decoration: InputDecoration(
                              labelText: 'Working Directory (Path)',
                              hintText: 'Defaults to directory containing the executable',
                              prefixIcon: const Icon(Icons.folder_special_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.folder_open),
                                onPressed: _pickWorkingDir,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _wmClassController,
                            decoration: const InputDecoration(
                              labelText: 'Startup WM Class',
                              hintText: 'e.g. cursor, obsidian (for dock icon grouping)',
                              prefixIcon: Icon(Icons.layers_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _customFileNameController,
                            decoration: const InputDecoration(
                              labelText: 'Custom .desktop Filename',
                              hintText: 'e.g. my-app.desktop (leave blank to auto-generate)',
                              prefixIcon: Icon(Icons.description_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Run in Terminal (Terminal=true)'),
                            subtitle: const Text('Open terminal window when launching (for CLI tools)'),
                            value: _terminal,
                            onChanged: (val) => setState(() => _terminal = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Add --no-sandbox argument'),
                            subtitle: const Text('Fixes Electron AppImages refusing to launch on Debian 13 / Ubuntu 24.04'),
                            value: _addNoSandbox,
                            onChanged: (val) => setState(() => _addNoSandbox = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF26A269), // Positive green
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handleAddToMenu,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.playlist_add_check, size: 22),
                        label: Text(
                          _isLoading ? 'Adding to Menu...' : 'Add to Menu',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _resetForm,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  if (_execController.text.trim().isNotEmpty)
                    IconButton.outlined(
                      tooltip: 'Test run executable directly',
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () {
                        DesktopEntryService.launchApp(
                          _execController.text,
                          workingDirectory: _workDirController.text,
                          terminal: _terminal,
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: formContent,
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: DesktopPreviewCard(entry: entry),
                ),
              ],
            ),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DesktopPreviewCard(entry: entry),
                const SizedBox(height: 20),
                formContent,
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
