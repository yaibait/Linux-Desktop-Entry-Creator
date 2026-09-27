<p align="center">
  <img src="assets/icons/app_icon.svg" width="128" height="128" alt="Linux Desktop Entry Creator Logo" />
</p>

<h1 align="center">Linux Desktop Entry Creator</h1>

<p align="center">
  <strong>A modern, intuitive Linux desktop utility built with Flutter for creating and managing <code>.desktop</code> launcher shortcuts for standalone applications, AppImages, portable binaries, and shell scripts.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux%20Desktop-E95420?logo=linux&logoColor=white" alt="Platform Linux" />
  <img src="https://img.shields.io/badge/Built%20with-Flutter%203-02569B?logo=flutter&logoColor=white" alt="Built with Flutter" />
  <img src="https://img.shields.io/badge/GTK-3.0-4A90E2?logo=gnome&logoColor=white" alt="GTK 3" />
  <img src="https://img.shields.io/badge/Application%20ID-com.binhmmo.app__launcher__creator-26A269" alt="App ID" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License MIT" />
</p>

---

## 📌 About The Project

Many Linux applications are distributed as standalone executables without system installers—such as **AppImages**, extracted `.tar.gz` archives (e.g., Blender, Cursor, Android Studio), custom binary builds, or shell scripts (`.sh`). 

Because they lack installers, these applications do not automatically appear in your desktop environment's Application Menu, App Grid, Dock, or search bar (GNOME Shell, KDE Plasma, XFCE, Cinnamon, Cosmic, etc.).

**Linux Desktop Entry Creator** solves this by providing a clean, graphical interface to configure, test, and register standardized FreeDesktop-compliant `.desktop` files into your user environment with a single click.

---

## ✨ Features

- 🎯 **Four Essential Inputs**:
  - **Application Name**: Name displayed in your desktop application menu and search. Auto-fills from the executable file name if selected first.
  - **Application Path (Executable)**: Select any `.AppImage`, Linux executable binary, or shell script (`.sh`). Includes a native file browser dialog and an option to automatically ensure executable permissions (`chmod +x`).
  - **Application Icon**: Browse and select any PNG, SVG, ICO, JPG, or WebP image. Includes a real-time preview and an option to safely copy the icon into `~/.local/share/icons/` so the shortcut never breaks if the source folder is moved.
  - **Application Category**: Select from standard FreeDesktop/XDG categories (`Utility`, `Development`, `Game`, `Graphics`, `AudioVideo`, `Network`, `Office`, `System`, `Settings`, `Education`, `Science`) with optional secondary tags (`IDE`, `TextEditor`, `WebBrowser`, etc.).

- 👁️ **Live Desktop Preview & Simulation**:
  - **OS Menu Mockup Card**: Real-time visual simulation of how your application card will look inside the desktop launcher / app grid.
  - **Syntax-Highlighted `.desktop` Code Viewer**: Watch the raw specification file generate in real time as you type, complete with a quick **Copy to Clipboard** button.

- ⚙️ **Power-User & Advanced Settings**:
  - **Working Directory (`Path=`)**: Automatically set to the executable's directory to ensure relative configuration and assets load properly.
  - **Terminal Mode (`Terminal=true`)**: Launch command-line utilities and scripts inside your default terminal emulator.
  - **`--no-sandbox` Flag Toggle**: Effortlessly fix modern Electron AppImages that refuse to launch on Debian 13 (Trixie) or Ubuntu 24.04+ due to unprivileged user namespace restrictions.
  - **Startup WM Class**: Associate running windows with dock launcher icons under Wayland and X11.

- 🗂️ **Integrated Launcher Manager**:
  - View all custom `.desktop` launchers installed in `~/.local/share/applications/`.
  - Filter and search through your portable applications.
  - **Test Run**: Launch the application directly to verify everything works.
  - **Edit & Reload**: Load existing desktop files back into the editor with one click.
  - **Delete**: Safely remove shortcuts and refresh the desktop database.

- 🎨 **Modern Linux Desktop Aesthetics**:
  - Designed according to modern Linux desktop guidelines (Adwaita / Material 3).
  - Full **Dark Mode** and **Light Mode** support.
  - Responsive two-column desktop layout.

---

## 🚀 Getting Started

### Prerequisites

To run or build this application on Linux, ensure you have the standard GTK3 and desktop libraries installed:

#### Debian / Ubuntu / Linux Mint
```bash
sudo apt update
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev
```

#### Fedora / RHEL
```bash
sudo dnf install clang cmake ninja-build pkgconfig gtk3-devel
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S clang cmake ninja pkgconf gtk3
```

---

### Running the Pre-compiled Release Build

If you cloned this repository with pre-built binaries:

```bash
cd app_icon
chmod +x run.sh
./run.sh
```

Or execute the release binary directly:
```bash
./build/linux/x64/release/bundle/app_launcher_creator
```

---

### Building from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/app_launcher_creator.git
   cd app_launcher_creator
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run in development mode**:
   ```bash
   flutter run -d linux
   ```

4. **Build release bundle**:
   ```bash
   flutter build linux --release
   ```
   The compiled application bundle will be located at `build/linux/x64/release/bundle/`.

---

### Running Tests

Ensure all unit tests and widget smoke tests pass:
```bash
flutter test
```

---

## 🛠️ How It Works (Under the Hood)

When you click **"Add to Menu"**, the application executes the following automated steps:

1. **Permission Check**: Automatically runs `chmod +x <executable_path>` if the file is not marked executable.
2. **Icon Preservation**: If enabled, copies the selected icon into `~/.local/share/icons/` using a sanitized slug name, preventing broken links.
3. **Spec Generation**: Constructs a compliant `[Desktop Entry]` file adhering to the [FreeDesktop Desktop Entry Specification 1.1](https://specifications.freedesktop.org/desktop-entry-spec/latest/).
4. **File Deployment**: Writes the file to `~/.local/share/applications/<app-name>.desktop` with `0755` permissions.
5. **Database Refresh**: Automatically runs `update-desktop-database ~/.local/share/applications` and `gtk-update-icon-cache` so your desktop environment updates its app grid immediately without requiring a logout or reboot.

---

## 📂 Project Architecture

```
app_icon/
├── assets/
│   └── icons/                 # Flat design application vector SVG & multi-res PNGs
├── lib/
│   ├── main.dart              # Application entry point & theme configuration
│   ├── models/
│   │   └── desktop_entry.dart # Desktop entry data model, escaping, and validation
│   ├── services/
│   │   ├── desktop_entry_service.dart # File system, permissions, and XDG database operations
│   │   └── file_picker_service.dart   # Native Linux file and folder selection dialogs
│   ├── theme/
│   │   └── app_theme.dart     # Adwaita / Material 3 Dark and Light color schemes
│   ├── widgets/
│   │   ├── desktop_preview_card.dart  # Real-time OS menu mockup & raw code preview
│   │   └── icon_preview_widget.dart   # Multi-format icon renderer (SVG, PNG, WebP)
│   └── screens/
│       ├── home_screen.dart           # Sidebar navigation rail & view management
│       ├── create_launcher_view.dart  # Primary launcher creation input form
│       ├── managed_launchers_view.dart# Manager for installed ~/.local/share/applications
│       └── guide_view.dart            # Helpful guide for AppImages, FUSE, and portable apps
├── linux/                     # Native GTK runner & CMake build configuration
├── test/                      # Unit and widget test suite
└── run.sh                     # Convenient executable launch script
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
