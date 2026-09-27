import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  /// Pick an executable file (binaries, .AppImage, .sh, all files)
  static Future<String?> pickExecutable() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Application Executable',
        type: FileType.any,
      );

      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (_) {
      // Fallback to zenity if FilePicker encountered an issue
      return _pickViaZenity(
        title: 'Select Application Executable',
        directoryOnly: false,
      );
    }
    return null;
  }

  /// Pick an icon file (png, svg, jpg, ico, xpm, webp)
  static Future<String?> pickIcon() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Select Application Icon',
        type: FileType.custom,
        allowedExtensions: ['png', 'svg', 'jpg', 'jpeg', 'ico', 'xpm', 'webp'],
      );

      if (result.isNotEmpty && result.first.path != null) {
        return result.first.path;
      }
    } catch (_) {
      // Fallback to zenity
      return _pickViaZenity(
        title: 'Select Application Icon',
        directoryOnly: false,
        fileFilter: 'Image files | *.png *.svg *.jpg *.jpeg *.ico *.xpm *.webp',
      );
    }
    return null;
  }

  /// Pick a working directory
  static Future<String?> pickDirectory({String? initialDirectory}) async {
    try {
      final result = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Working Directory',
        initialDirectory: initialDirectory,
      );
      if (result != null && result.isNotEmpty) {
        return result;
      }
    } catch (_) {
      return _pickViaZenity(
        title: 'Select Working Directory',
        directoryOnly: true,
      );
    }
    return null;
  }

  /// Direct fallback using Linux zenity dialog
  static Future<String?> _pickViaZenity({
    required String title,
    required bool directoryOnly,
    String? fileFilter,
  }) async {
    try {
      final args = ['--file-selection', '--title=$title'];
      if (directoryOnly) {
        args.add('--directory');
      }
      if (fileFilter != null) {
        args.add('--file-filter=$fileFilter');
      }

      final proc = await Process.run('zenity', args);
      if (proc.exitCode == 0) {
        final path = (proc.stdout as String).trim();
        if (path.isNotEmpty) {
          return path;
        }
      }
    } catch (_) {
      // Zenity not available or user cancelled
    }
    return null;
  }
}
