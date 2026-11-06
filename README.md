# Minecraft Desktop Pet

[![Windows 10/11 x64](https://img.shields.io/badge/Windows-10%20%2F%2011%20x64-0078D6)](https://github.com/jasonhukom/Desktop-Pet/releases/latest) [![macOS Apple Silicon 12+ | Intel 13+](https://img.shields.io/badge/macOS-Apple%20Silicon%2012%2B%20%7C%20Intel%2013%2B-000000?logo=apple)](https://github.com/jasonhukom/Desktop-Pet/releases/latest) [![Release](https://img.shields.io/github/v/release/jasonhukom/Desktop-Pet)](https://github.com/jasonhukom/Desktop-Pet/releases/latest) [![License: MIT](https://img.shields.io/github/license/jasonhukom/Desktop-Pet)](LICENSE)

Have a Minecraft-style character sit on your desktop, track your cursor, and keep you company as you type.

**Created by GPT 6 Astra**

> This project is an independent fan work and is not affiliated with, endorsed by, sponsored by, or officially approved by Mojang Studios or Microsoft. The Minecraft name and related trademarks belong to their respective owners.

## Downloads & Editions

Choose between two distinct editions depending on the experience you want:

---

### 1. 🌐 Classic / Multilingual Edition (`v1.0.1`)
*The original, faithful Minecraft desktop companion with comprehensive internationalization.*

- **What it is**: The classic desktop pet with stable, true-to-game Minecraft animation mechanics, plus full internationalization support.
- **Key Features**:
  - **85+ Languages**: Full UI translations across settings, tabs, labels, and context menus.
  - **Keyboard Alphabet Typing**: Animated typing letters automatically adapt to your active language and keyboard layout.
  - **High-Quality Unicode Glyphs**: Crisp rasterization for Cyrillic, Greek, Arabic, Hebrew, CJK, Indic, and European alphabets.
  - **Standard Minecraft Poses**: Classic standing, sitting, sneaking, and custom posing without exaggerated jelly physics.
- **Downloads (`v1.0.1`)**:
  - 🪟 **Windows 10/11 x64**: [Minecraft-Desktop-Pet-1.0.1-Windows.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1/Minecraft-Desktop-Pet-1.0.1-Windows.zip) *(Portable `.exe`)*
  - 🍏 **macOS Universal**: [Minecraft-Desktop-Pet-1.0.1-mac-universal.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1/Minecraft-Desktop-Pet-1.0.1-mac-universal.zip) *(Apple Silicon + Intel)*
  - 🍏 **macOS Apple Silicon**: [Minecraft-Desktop-Pet-1.0.1-mac-AppleSilicon.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1/Minecraft-Desktop-Pet-1.0.1-mac-AppleSilicon.zip) *(M1/M2/M3/M4)*
  - 🍏 **macOS Intel**: [Minecraft-Desktop-Pet-1.0.1-mac-Intel.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1/Minecraft-Desktop-Pet-1.0.1-mac-Intel.zip) *(x86_64)*

---

### 2. ⚡ Bounce Edition (`v1.0.1.b Bounce`)
*A completely different, lively physics-driven sandbox experience!*

- **What it is**: Transforms the pet into a bouncy, springy, expressive jelly companion that reacts dynamically to being dragged, tossed, shaken, and petted.
- **Key Features**:
  - **Bouncy Jelly Physics**: Squashes, stretches, tilts, and wobbles with spring physics during movement and interactions.
  - **Drag & Throw Momentum**: Pick up your pet, flick or throw them across your desktop, and watch them rebound off screen edges with realistic inertia.
  - **Petting & Rubbing (Hearts)**: Rubbing the mouse back and forth over the pet spawns floating Minecraft heart particles.
  - **Dizzy Shaking (Stars)**: Violently shaking the pet disorients them and spawns dizzy spinning stars.
  - **Mouse Wheel Scaling**: Scroll your mouse wheel directly over the pet to smoothly grow or shrink their size on the desktop.
  - **Includes All v1.0.1 Languages**: Retains the 85+ language switcher, translations, and layout-aware typing animations.
- **Downloads (`v1.0.1.b Bounce`)**:
  - 🪟 **Windows 10/11 x64**: [Minecraft-Desktop-Pet-1.0.1-Windows.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1.b/Minecraft-Desktop-Pet-1.0.1-Windows.zip) *(Portable `.exe`)*
  - 🍏 **macOS Universal**: [Minecraft-Desktop-Pet-1.0.1-mac-universal.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1.b/Minecraft-Desktop-Pet-1.0.1-mac-universal.zip) *(Apple Silicon + Intel)*
  - 🍏 **macOS Apple Silicon**: [Minecraft-Desktop-Pet-1.0.1-mac-AppleSilicon.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1.b/Minecraft-Desktop-Pet-1.0.1-mac-AppleSilicon.zip) *(M1/M2/M3/M4)*
  - 🍏 **macOS Intel**: [Minecraft-Desktop-Pet-1.0.1-mac-Intel.zip](https://github.com/jasonhukom/Desktop-Pet/releases/download/v1.0.1.b/Minecraft-Desktop-Pet-1.0.1-mac-Intel.zip) *(x86_64)*

---

**Tip**: **Full mouse click-through is enabled by default on first launch.** Double-click the tray icon to open Settings/Console; disable "Click-Through" first when you want to drag the pet. The icon may be located in the taskbar overflow area.

## Features

- Import local PNG skins or enter an official Java Edition username / UUID to fetch skins; supports classic and slim arms, legacy and HD skins, and outer skin layers.
- Stand, sit, or customize standing and sitting poses independently. Limbs and torso can rotate without elbow/knee bends.
- Head tracks the mouse cursor; horizontal and vertical sensitivity, range, and center offsets are adjustable; overall model orientation can also be adjusted.
- Hold Shift while standing to sneak instantly; while sitting, strikes the keyboard in sync with global typing, supporting precise positions and alternating hands.
- Long-pressing a key holds the hand position, smoothly returning to rest upon release. Briefly squashes body when typing, with adjustable depth; rapid typing retriggers animations.
- Click mouse buttons to swing the main hand; switchable between left and right hand; continuous clicks re-swing immediately.
- Always on top, scaling, free dragging/placement, and full mouse click-through.
- Optional autostart on Windows / macOS login, toggled via the settings panel or context menu.
- Fetching skin with an official ID retrieves and equips the account's cape on its back. When click-through is enabled, moving the mouse over the pet fades opacity to 25% within ~0.15s.
- Optional **hyp quick team chat**: typing `#` on your keyboard automatically replaces it with `/p chat `, without sending automatically.
- 7 FPS tiers (30 / 60 / 90 / 120 / 144 / 165 / 240 FPS); stops drawing when idle to save CPU. Preferences and imported skins are saved automatically.

## FAQ

**Q: How do I move the desktop pet?**  
A: Freshly downloaded pets have full mouse click-through enabled by default. Find the Creeper icon in the taskbar tray, right-click (or double-click) it, and uncheck "Click-Through" to drag the pet.

**Q: What if I don't have an official Minecraft account?**  
A: You can enter any player's Minecraft username, or import a local skin PNG file directly.

**Q: Why does antivirus flag the application?**  
A: This can happen because the executable does not have an expensive commercial code-signing certificate, resulting in false positives. The pet contains no malware. Please make sure you downloaded it from the official GitHub release!

**Q: Why doesn't the character type on macOS?**  
A: macOS requires granting "Input Monitoring" permission to the pet to observe global keystrokes. Open Settings and check the bottom status line: a red "Keyboard interaction awaiting authorization" indicates missing permissions. Click "Input Permissions…" → "Request Input Monitoring", drag the pet icon from the popup card into the System Settings "Input Monitoring" list, enable the toggle, and restart the pet. Without permission, the character only types in its own windows (such as Settings).

**Q: Why did the character stop typing after updating on macOS?**  
A: macOS stores permissions against the old version of the app bundle, which may become invalidated upon replacement even if System Settings still shows it as enabled. In "System Settings → Privacy & Security → Input Monitoring", select the old "Minecraft Desktop Pet", click "−" to delete it, then re-grant permission as described above and restart the pet. If quick chat is enabled, repeat this for "Accessibility".

## Privacy & Network

Daily interactions are processed strictly locally on your machine. In regular operation, no typed text is recorded or keystrokes uploaded. Mojang's official profile and texture servers are contacted only when actively fetching an official skin; GitHub is contacted only when clicking "Check Updates". No passwords or credentials are ever required. When music notes are enabled, only local audio playback sessions are queried; no audio is recorded or uploaded.

## Credits & Team

- @DLmember (Owner)
- @vanillaQAQ (macOS maintainer)
- @H0mble (Linux contributor)

**Other contributors:**

- Pet optimizations and feature contributions: Bilibili @汐颜摸大鱼, Bilibili @星蓝想睡觉, @zsyghxf, @RuiShu1024, @Kevae12138
- Generous token sponsorship: @Sullove0685
- And all users who reported bugs and helped test and troubleshoot!

## Building from Source

Source code is located in `native/src`; initial first-run defaults in `native/default-settings.json`; built-in skin and icons in `assets`.

### Windows

Native Rust + Win32 implementation using CPU rendering for the transparent cuboid model, containing no browser or web runtime.

1. Install the Rust `stable-x86_64-pc-windows-gnu` toolchain.
2. Install the x86_64 UCRT version of [LLVM-MinGW](https://github.com/mstorsjo/llvm-mingw/releases), including `clang++.exe`, `windres.exe`, and `x86_64-w64-mingw32-gcc.exe`.
3. It is recommended to place the repository in a path without spaces or non-ASCII characters, then run:

```powershell
rustup toolchain install stable-x86_64-pc-windows-gnu
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -ToolchainBin C:\llvm-mingw\bin
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Action test -ToolchainBin C:\llvm-mingw\bin
```

Output: `native/target/release/minecraft-pet.exe`. The script uses dependencies locked in `Cargo.lock`. First build requires network access to download dependencies. The GNU toolchain version can be specified via `-RustToolchain`.

### macOS

Native macOS port reusing the core Rust rendering, skin, and animation logic, providing a transparent window, menu bar item, settings console, and global keyboard interaction via Swift / AppKit, along with optional `#` quick chat prefix replacement.
Supports Apple Silicon (macOS 12+) and Intel (macOS 13+), built as a universal binary.
See [macOS Instructions](macos/使用说明-macOS.md) for detailed documentation.

Requires Xcode Command Line Tools, Swift, and Rust stable:

```bash
rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo test --manifest-path native/Cargo.toml --lib --locked
scripts/build-macos.sh /absolute/path/to/output
```

Default outputs are placed in `release/macos/`: universal `Minecraft Desktop Pet.app`, as well as single-architecture builds under `AppleSilicon/` and `Intel/`, each with accompanying ZIP archives. Build script uses local ad-hoc code signing without Apple notarization.

## License

Application code and the project's original sample skin are licensed under the [MIT License](LICENSE). Dependency licenses are detailed in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and `native/licenses/`. User-imported skins are not covered by this repository's license; please respect original authors' rights.
