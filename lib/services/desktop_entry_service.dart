import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/desktop_entry.dart';

class ExistingDesktopEntry {
  final String filePath;
  final String fileName;
  final String name;
  final String exec;
  final String icon;
  final String categories;
  final String comment;
  final bool terminal;
  final String workingDirectory;
  final DateTime lastModified;

  ExistingDesktopEntry({
    required this.filePath,
    required this.fileName,
    required this.name,
    required this.exec,
    required this.icon,
    required this.categories,
    required this.comment,
    required this.terminal,
    required this.workingDirectory,
    required this.lastModified,
  });
}

class DesktopEntryResult {
  final bool success;
  final String message;
  final String? desktopFilePath;
  final String? copiedIconPath;

  DesktopEntryResult({
    required this.success,
    required this.message,
    this.desktopFilePath,
    this.copiedIconPath,
  });
}

class DesktopEntryService {
  static String get homeDir {
    return Platform.environment['HOME'] ?? '/home/${Platform.environment['USER']}';
  }

  static String get applicationsDirectory {
    final xdgData = Platform.environment['XDG_DATA_HOME'];
    if (xdgData != null && xdgData.trim().isNotEmpty) {
      return p.join(xdgData, 'applications');
    }
    return p.join(homeDir, '.local', 'share', 'applications');
  }

  static String get iconsDirectory {
    final xdgData = Platform.environment['XDG_DATA_HOME'];
    if (xdgData != null && xdgData.trim().isNotEmpty) {
      return p.join(xdgData, 'icons');
    }
    return p.join(homeDir, '.local', 'share', 'icons');
  }

  /// Adds application to OS Application Menu
  static Future<DesktopEntryResult> addToMenu(DesktopEntry entry) async {
    try {
      if (entry.name.trim().isEmpty) {
        return DesktopEntryResult(
          success: false,
          message: 'Application Name cannot be empty.',
        );
      }

      if (entry.execPath.trim().isEmpty) {
        return DesktopEntryResult(
          success: false,
          message: 'Application Executable Path cannot be empty.',
        );
      }

      final execFile = File(entry.execPath.trim());
      if (!await execFile.exists()) {
        return DesktopEntryResult(
          success: false,
          message: 'Executable file not found at: ${entry.execPath}',
        );
      }

      // 1. Make executable if requested
      if (entry.makeExecutable) {
        try {
          await Process.run('chmod', ['+x', entry.execPath.trim()]);
        } catch (e) {
          // Non-fatal warning
        }
      }

      // 2. Ensure application directories exist
      final appsDir = Directory(applicationsDirectory);
      if (!await appsDir.exists()) {
        await appsDir.create(recursive: true);
      }

      // 3. Handle icon copying if selected
      String? finalIconPath = entry.iconPath.trim();
      String? copiedIconPath;

      if (entry.copyIcon && entry.iconPath.trim().isNotEmpty) {
        final iconFile = File(entry.iconPath.trim());
        if (await iconFile.exists()) {
          final iconsDir = Directory(iconsDirectory);
          if (!await iconsDir.exists()) {
            await iconsDir.create(recursive: true);
          }

          final ext = p.extension(entry.iconPath.trim());
          final baseSlug = p.basenameWithoutExtension(entry.fileName);
          final destIconFile = File(p.join(iconsDirectory, '$baseSlug$ext'));

          try {
            await iconFile.copy(destIconFile.path);
            finalIconPath = destIconFile.path;
            copiedIconPath = destIconFile.path;
          } catch (e) {
            // Keep original path if copying fails
            finalIconPath = entry.iconPath.trim();
          }
        }
      }

      // 4. Generate .desktop content
      final content = entry.generateContent(finalIconPath: finalIconPath);
      final destDesktopFile = File(p.join(applicationsDirectory, entry.fileName));

      // 5. Write .desktop file
      await destDesktopFile.writeAsString(content, flush: true);

      // 6. Make .desktop executable
      try {
        await Process.run('chmod', ['755', destDesktopFile.path]);
      } catch (_) {}

      // 7. Update desktop database
      await refreshDesktopDatabase();

      return DesktopEntryResult(
        success: true,
        message: 'Successfully added "${entry.name}" to Linux application menu!',
        desktopFilePath: destDesktopFile.path,
        copiedIconPath: copiedIconPath,
      );
    } catch (e) {
      return DesktopEntryResult(
        success: false,
        message: 'Failed to create desktop entry: $e',
      );
    }
  }

  /// Triggers OS desktop database and icon cache updates
  static Future<void> refreshDesktopDatabase() async {
    try {
      await Process.run('update-desktop-database', [applicationsDirectory]);
    } catch (_) {}

    try {
      await Process.run('gtk-update-icon-cache', ['-f', '-t', iconsDirectory]);
    } catch (_) {}
  }

  /// Reads user's local .desktop files
  static Future<List<ExistingDesktopEntry>> listUserEntries() async {
    final list = <ExistingDesktopEntry>[];
    final dir = Directory(applicationsDirectory);
    if (!await dir.exists()) return list;

    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.desktop')) {
        try {
          final content = await entity.readAsString();
          final lines = const LineSplitter().convert(content);

          String name = '';
          String exec = '';
          String icon = '';
          String categories = '';
          String comment = '';
          String workingDir = '';
          bool terminal = false;

          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.startsWith('Name=')) {
              name = trimmed.substring(5).trim();
            } else if (trimmed.startsWith('Exec=')) {
              exec = trimmed.substring(5).trim();
            } else if (trimmed.startsWith('Icon=')) {
              icon = trimmed.substring(5).trim();
            } else if (trimmed.startsWith('Categories=')) {
              categories = trimmed.substring(11).trim();
            } else if (trimmed.startsWith('Comment=')) {
              comment = trimmed.substring(8).trim();
            } else if (trimmed.startsWith('Path=')) {
              workingDir = trimmed.substring(5).trim();
            } else if (trimmed.startsWith('Terminal=')) {
              terminal = trimmed.substring(9).trim().toLowerCase() == 'true';
            }
          }

          final stat = await entity.stat();
          list.add(ExistingDesktopEntry(
            filePath: entity.path,
            fileName: p.basename(entity.path),
            name: name.isNotEmpty ? name : p.basenameWithoutExtension(entity.path),
            exec: exec,
            icon: icon,
            categories: categories,
            comment: comment,
            terminal: terminal,
            workingDirectory: workingDir,
            lastModified: stat.modified,
          ));
        } catch (_) {}
      }
    }

    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return list;
  }

  /// Delete a desktop entry
  static Future<bool> deleteEntry(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        await refreshDesktopDatabase();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Test launch the application
  static Future<bool> launchApp(
    String execPath, {
    String? workingDirectory,
    bool terminal = false,
  }) async {
    try {
      String cleanExec = execPath.trim();
      // Remove placeholder args like %u, %U, %f, %F
      cleanExec = cleanExec.replaceAll(RegExp(r'%[a-zA-Z]'), '').trim();

      if (terminal) {
        // Try common terminal emulators
        final terminals = ['x-terminal-emulator', 'gnome-terminal', 'konsole', 'xfce4-terminal', 'ptyxis', 'alacritty', 'kitty', 'xterm'];
        for (final term in terminals) {
          try {
            final check = await Process.run('which', [term]);
            if (check.exitCode == 0) {
              if (term == 'gnome-terminal' || term == 'ptyxis') {
                await Process.start(term, ['--', 'bash', '-c', '$cleanExec; exec bash'],
                    workingDirectory: workingDirectory,
                    mode: ProcessStartMode.detached);
              } else {
                await Process.start(term, ['-e', 'bash -c "$cleanExec; exec bash"'],
                    workingDirectory: workingDirectory,
                    mode: ProcessStartMode.detached);
              }
              return true;
            }
          } catch (_) {}
        }
      }

      // Normal GUI launch
      final parts = _parseCommand(cleanExec);
      if (parts.isNotEmpty) {
        await Process.start(
          parts[0],
          parts.length > 1 ? parts.sublist(1) : [],
          workingDirectory: workingDirectory != null && workingDirectory.isNotEmpty ? workingDirectory : null,
          mode: ProcessStartMode.detached,
        );
        return true;
      }
    } catch (e) {
      // Fallback: run via sh -c
      try {
        await Process.start('sh', ['-c', execPath.replaceAll(RegExp(r'%[a-zA-Z]'), '')],
            workingDirectory: workingDirectory,
            mode: ProcessStartMode.detached);
        return true;
      } catch (_) {}
    }
    return false;
  }

  /// Opens application folder in default file manager
  static Future<void> openApplicationsFolder() async {
    try {
      final dir = Directory(applicationsDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      await Process.start('xdg-open', [applicationsDirectory], mode: ProcessStartMode.detached);
    } catch (_) {}
  }

  /// Simple command line parser supporting quotes
  static List<String> _parseCommand(String cmd) {
    final tokens = <String>[];
    final sb = StringBuffer();
    bool inQuote = false;
    String quoteChar = '';

    for (int i = 0; i < cmd.length; i++) {
      final char = cmd[i];
      if ((char == '"' || char == "'")) {
        if (!inQuote) {
          inQuote = true;
          quoteChar = char;
        } else if (quoteChar == char) {
          inQuote = false;
          quoteChar = '';
        } else {
          sb.write(char);
        }
      } else if (char == ' ' && !inQuote) {
        if (sb.isNotEmpty) {
          tokens.add(sb.toString());
          sb.clear();
        }
      } else {
        sb.write(char);
      }
    }
    if (sb.isNotEmpty) {
      tokens.add(sb.toString());
    }
    return tokens;
  }
}
