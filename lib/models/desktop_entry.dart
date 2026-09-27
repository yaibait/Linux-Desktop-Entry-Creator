import 'package:path/path.dart' as p;

class DesktopEntry {
  String name;
  String execPath;
  String iconPath;
  String category;
  List<String> additionalCategories;
  String comment;
  String genericName;
  String workingDirectory;
  bool terminal;
  bool startupNotify;
  String startupWmClass;
  bool makeExecutable;
  bool copyIcon;
  bool addNoSandbox;
  String customFileName;

  DesktopEntry({
    this.name = '',
    this.execPath = '',
    this.iconPath = '',
    this.category = 'Utility',
    List<String>? additionalCategories,
    this.comment = '',
    this.genericName = '',
    this.workingDirectory = '',
    this.terminal = false,
    this.startupNotify = true,
    this.startupWmClass = '',
    this.makeExecutable = true,
    this.copyIcon = true,
    this.addNoSandbox = false,
    this.customFileName = '',
  }) : additionalCategories = additionalCategories ?? [];

  /// Generates a sanitized desktop file name e.g. "my-app.desktop"
  String get fileName {
    if (customFileName.trim().isNotEmpty) {
      String fn = customFileName.trim();
      if (!fn.endsWith('.desktop')) {
        fn = '$fn.desktop';
      }
      return _sanitizeFileName(fn);
    }

    String base = name.trim();
    if (base.isEmpty && execPath.trim().isNotEmpty) {
      base = p.basenameWithoutExtension(execPath.trim());
    }
    if (base.isEmpty) {
      base = 'custom-app';
    }

    final sanitized = _sanitizeFileName(
      base.toLowerCase().replaceAll(RegExp(r'\s+'), '-'),
    );
    return '$sanitized.desktop';
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
  }

  /// Formats the Exec key according to Desktop Entry spec.
  /// If the path contains spaces, it quotes it.
  String get formattedExec {
    String exec = execPath.trim();
    if (exec.isEmpty) return '';

    String quotedExec;
    if (exec.contains(' ') && !exec.startsWith('"') && !exec.startsWith("'")) {
      quotedExec = '"$exec"';
    } else {
      quotedExec = exec;
    }

    if (addNoSandbox && !quotedExec.contains('--no-sandbox')) {
      quotedExec = '$quotedExec --no-sandbox';
    }

    // Pass file/URL argument %U if not specified
    if (!quotedExec.contains('%')) {
      quotedExec = '$quotedExec %U';
    }

    return quotedExec;
  }

  /// Aggregates all categories into the standardized semicolon-delimited string
  String get formattedCategories {
    final catSet = <String>{};
    if (category.trim().isNotEmpty) {
      catSet.add(category.trim());
    }
    for (final c in additionalCategories) {
      if (c.trim().isNotEmpty) {
        catSet.add(c.trim());
      }
    }
    if (catSet.isEmpty) {
      catSet.add('Utility');
    }
    return '${catSet.join(';')};';
  }

  /// Builds the complete standard .desktop file content
  String generateContent({String? finalIconPath}) {
    final effectiveIcon = (finalIconPath ?? iconPath).trim();
    final buffer = StringBuffer();
    buffer.writeln('[Desktop Entry]');
    buffer.writeln('Type=Application');
    buffer.writeln('Version=1.1');
    buffer.writeln('Name=${name.trim().isEmpty ? "Unnamed Application" : name.trim()}');

    if (genericName.trim().isNotEmpty) {
      buffer.writeln('GenericName=${genericName.trim()}');
    }

    if (comment.trim().isNotEmpty) {
      buffer.writeln('Comment=${comment.trim()}');
    }

    buffer.writeln('Exec=$formattedExec');

    if (effectiveIcon.isNotEmpty) {
      buffer.writeln('Icon=$effectiveIcon');
    }

    final effectiveWorkDir = workingDirectory.trim().isNotEmpty
        ? workingDirectory.trim()
        : (execPath.trim().isNotEmpty ? p.dirname(execPath.trim()) : '');

    if (effectiveWorkDir.isNotEmpty && effectiveWorkDir != '.') {
      buffer.writeln('Path=$effectiveWorkDir');
    }

    buffer.writeln('Terminal=${terminal ? 'true' : 'false'}');
    buffer.writeln('StartupNotify=${startupNotify ? 'true' : 'false'}');
    buffer.writeln('Categories=$formattedCategories');

    if (startupWmClass.trim().isNotEmpty) {
      buffer.writeln('StartupWMClass=${startupWmClass.trim()}');
    }

    return buffer.toString();
  }
}
