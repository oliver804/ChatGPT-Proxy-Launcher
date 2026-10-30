# Usage boundaries

[中文](USAGE.md) | **English**

Local Route Launcher is an independent, MIT-licensed utility that passes local HTTP proxy settings to compatible applications. It is not a proxy provider, VPN, ChatGPT client, or OpenAI service. It does not include ChatGPT binaries or grant access to accounts, subscriptions, or restricted services.

Use it only with networks, proxy services, and accounts you are authorized to use. Applicable laws, network policies, and third-party service terms still apply. The project does not authorize bypassing access restrictions, account controls, rate limits, or other protective measures. Availability and permission to access a service are separate from whether a connection succeeds.

Compatibility is limited to detectable Electron-based ChatGPT installations on Apple Silicon with macOS 13+, or Windows 10 22H2 / Windows 11 x64. Updates to the target application can change its behavior. The launcher cannot guarantee that all traffic follows the supplied settings: voice, WebRTC, UDP, and some child processes may behave differently. Diagnostics are snapshots, not a privacy, anonymity, security, or account-access guarantee.

ChatGPT and OpenAI are trademarks of OpenAI. Their names identify compatibility only. This project is not affiliated with, sponsored by, or endorsed by OpenAI. The historical repository URL and internal preferences identifier are retained for link continuity and upgrades; the application’s public name is Local Route Launcher.

macOS release binaries are ad-hoc signed and are not Apple Developer ID signed or notarized. Review the source, release checksums, compatibility notes, and macOS prompts before installation. The [MIT license](../LICENSE) covers the project code and its warranty limitations; it does not grant rights to third-party trademarks or services. [Privacy](PRIVACY.en.md) · [Third-party notices](../THIRD_PARTY_NOTICES.md).

Windows: requires a directly launchable Electron-based ChatGPT.exe; restricted Microsoft Store packages may reject direct launch. Windows ARM64 is not supported. Windows installers are unsigned and may trigger SmartScreen. Do not disable security protections or bypass managed-device policies.

## Interface and updates in 1.4.0

Select an app in the sidebar and save its host, port and path independently. Language, appearance and GitHub controls live at the upper right and are also available in the menu/tray panel. Closing the main window keeps the launcher accessible there.

The version-adjacent badge appears only when a newer stable launcher release has an installer for this platform. Clicking downloads that installer directly in your browser, without an intermediate panel. Run the downloaded installer to finish updating. No badge is shown otherwise; offline checks do not interrupt use.
