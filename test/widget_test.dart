import 'package:flutter_test/flutter_test.dart';
import 'package:app_launcher_creator/main.dart';
import 'package:app_launcher_creator/models/desktop_entry.dart';

void main() {
  group('DesktopEntry Model Tests', () {
    test('generateContent produces compliant freedesktop format', () {
      final entry = DesktopEntry(
        name: 'Obsidian',
        execPath: '/home/user/Applications/obsidian.AppImage',
        iconPath: '/home/user/Applications/obsidian.png',
        category: 'Office',
        additionalCategories: ['Utility'],
        comment: 'Markdown Knowledge Base',
      );

      final content = entry.generateContent();
      expect(content, contains('[Desktop Entry]'));
      expect(content, contains('Type=Application'));
      expect(content, contains('Name=Obsidian'));
      expect(content, contains('Exec=/home/user/Applications/obsidian.AppImage %U'));
      expect(content, contains('Icon=/home/user/Applications/obsidian.png'));
      expect(content, contains('Categories=Office;Utility;'));
      expect(content, contains('Comment=Markdown Knowledge Base'));
      expect(content, contains('Terminal=false'));
    });

    test('fileName sanitizes spaces and special characters', () {
      final entry = DesktopEntry(
        name: 'My Cool App 2.0',
        execPath: '/tmp/run.sh',
      );
      expect(entry.fileName, equals('my-cool-app-2.0.desktop'));
    });

    test('quotedExec quotes path containing spaces', () {
      final entry = DesktopEntry(
        name: 'Space App',
        execPath: '/home/user/My Apps/run me.AppImage',
      );
      expect(entry.formattedExec, equals('"/home/user/My Apps/run me.AppImage" %U'));
    });

    test('addNoSandbox adds --no-sandbox argument', () {
      final entry = DesktopEntry(
        name: 'Cursor',
        execPath: '/opt/cursor.AppImage',
        addNoSandbox: true,
      );
      expect(entry.formattedExec, contains('--no-sandbox'));
    });
  });

  group('Widget Tests', () {
    testWidgets('App renders main navigation and form inputs', (WidgetTester tester) async {
      await tester.pumpWidget(const DesktopEntryCreatorApp());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Application Name *'), findsOneWidget);
      expect(find.text('Application Path (Executable) *'), findsOneWidget);
      expect(find.text('Application Icon'), findsOneWidget);
      expect(find.text('Application Category *'), findsOneWidget);
      expect(find.text('Add to Menu'), findsOneWidget);
    });
  });
}
