import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DesktopEntryCreatorApp());
}

class DesktopEntryCreatorApp extends StatefulWidget {
  const DesktopEntryCreatorApp({super.key});

  @override
  State<DesktopEntryCreatorApp> createState() => _DesktopEntryCreatorAppState();
}

class _DesktopEntryCreatorAppState extends State<DesktopEntryCreatorApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linux Desktop Entry Creator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: HomeScreen(
        currentThemeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
      ),
    );
  }
}
