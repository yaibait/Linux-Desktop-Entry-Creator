import 'package:flutter/material.dart';

import '../models/desktop_entry.dart';
import 'create_launcher_view.dart';
import 'managed_launchers_view.dart';
import 'guide_view.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DesktopEntry? _entryToEdit;

  void _onEditEntry(DesktopEntry entry) {
    setState(() {
      _entryToEdit = entry;
      _selectedIndex = 0; // Switch to Create / Edit tab
    });
  }

  void _onLauncherCreated() {
    // Launcher created successfully
    setState(() {
      _entryToEdit = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Desktop Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
                if (index != 0) {
                  _entryToEdit = null;
                }
              });
            },
            minWidth: 72,
            minExtendedWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3584E4), Color(0xFF1C71D8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3584E4).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.launch, color: Colors.white, size: 26),
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton.outlined(
                    tooltip: isDark
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    onPressed: () {
                      widget.onThemeModeChanged(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                  ),
                ),
              ),
            ),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps),
                label: Text('Installed'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help_outline),
                selectedIcon: Icon(Icons.help),
                label: Text('Guide'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Main Screen Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                CreateLauncherView(
                  key: ValueKey(_entryToEdit?.fileName ?? 'new'),
                  initialEntry: _entryToEdit,
                  onCreated: _onLauncherCreated,
                ),
                ManagedLaunchersView(onEditEntry: _onEditEntry),
                const GuideView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
