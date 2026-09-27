import 'package:flutter/material.dart';
import '../services/desktop_entry_service.dart';

class GuideView extends StatelessWidget {
  const GuideView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Linux Standalone Apps Guide',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Quick tips and best practices for running portable applications on Linux.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          _buildTipCard(
            context,
            icon: Icons.extension_outlined,
            title: 'What are .desktop files?',
            content:
                'On Linux desktop environments (GNOME, KDE Plasma, XFCE, Cinnamon, etc.), application menus and docks scan specific directories for ".desktop" files.\n\n'
                'By writing your custom launchers into "~/.local/share/applications", they appear directly in your Application menu, App Grid, and search without needing root/sudo permissions.',
          ),
          const SizedBox(height: 16),

          _buildTipCard(
            context,
            icon: Icons.apps_outlined,
            title: 'Handling AppImages',
            content:
                '1. Executable Permissions: AppImages must have the executable permission set (chmod +x). This tool automatically checks and sets this for you.\n'
                '2. Electron Sandbox: On modern distributions like Debian 13 (Trixie) and Ubuntu 24.04+, unprivileged user namespaces are restricted. If an Electron AppImage fails to start, enable the "Add --no-sandbox argument" switch in Advanced Options.\n'
                '3. AppImage Icon Extraction: You can extract an AppImage\'s built-in icon using: "./app.AppImage --appimage-extract". The icon will be in the "squashfs-root" folder.',
          ),
          const SizedBox(height: 16),

          _buildTipCard(
            context,
            icon: Icons.folder_zip_outlined,
            title: 'Tar.gz / Zip Portable Binaries',
            content:
                '1. Extract your portable application into a permanent directory like "~/Applications" or "~/.local/share/my-app".\n'
                '2. Point the "Application Path" to the main executable binary inside that folder.\n'
                '3. The "Working Directory" (Path=) is automatically set to the folder containing the executable so relative assets load properly.',
          ),
          const SizedBox(height: 16),

          _buildTipCard(
            context,
            icon: Icons.terminal_outlined,
            title: 'Shell Scripts & CLI Tools',
            content:
                'If your application is a shell script (.sh) or an interactive terminal command (e.g. htop, btop, ranger):\n'
                '1. Enable the "Run in Terminal" option in Advanced Options.\n'
                '2. The launcher will automatically open your default terminal emulator to run the command.',
          ),
          const SizedBox(height: 24),

          Center(
            child: OutlinedButton.icon(
              onPressed: DesktopEntryService.openApplicationsFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open ~/.local/share/applications in File Manager'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
