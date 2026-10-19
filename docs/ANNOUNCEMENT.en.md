# Local Route Launcher now supports Windows and macOS

I built Local Route Launcher to launch a compatible ChatGPT desktop app with an existing HTTP proxy, without changing system proxy or DNS settings. The project started on macOS; **v1.2.0 adds an installable Windows edition**.

## What’s new

- **Windows x64 installer:** a per-user EXE with the .NET runtime included. No developer tools or separate runtime installation needed.
- **English and Simplified Chinese**, light and dark themes, and system tray controls. Close the window and reopen it from the tray.
- **Local diagnostics:** inspect transport reachability, the running app’s proxy arguments, and its TCP connection snapshot.
- **macOS remains supported** with its DMG and menu bar controls.

Install the launcher, keep a proxy you are authorized to use running, save its address and port, then quit ChatGPT and reopen it through the launcher. On Windows, it searches installed packages; you can also select a compatible `ChatGPT.exe` manually.

## Compatibility and boundaries

The release targets **Windows 10 22H2 / Windows 11 x64** and **macOS 13+ on Apple Silicon**. It requires a detectable Electron-based ChatGPT installation. Older native apps, Windows ARM64 and Intel Macs are not supported. Some restricted Microsoft Store packages may not allow direct launch.

The launcher provides no proxy service and does not guarantee that every protocol or child process follows the settings. Voice, WebRTC and UDP may behave differently. Diagnostics are snapshots, not a guarantee of complete routing or account access.

Windows build checks use an isolated fixture to test the installed app, arguments, connections and graceful shutdown; they do not establish compatibility with every ChatGPT version or a signed-in account. Windows installers are not Authenticode-signed; macOS builds are ad-hoc signed and not notarized. Verify the release source and checksums and keep system protections enabled.

[Download v1.2.0](https://github.com/oliver804/ChatGPT-Proxy-Launcher/releases/tag/v1.2.0) · [Source code](https://github.com/oliver804/ChatGPT-Proxy-Launcher) · [Website](https://oliver804.github.io/ChatGPT-Proxy-Launcher/en/)

Free and open source under MIT. Feedback on Windows compatibility is welcome, especially the app version, installation source, and sanitized error details.

Independent project, not affiliated with or endorsed by OpenAI. ChatGPT is a trademark of OpenAI, used here to identify compatibility. Use only authorized networks and services in accordance with applicable laws and service terms.

— Oliver

*This article was drafted with AI assistance.*
