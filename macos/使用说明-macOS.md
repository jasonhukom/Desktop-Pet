# Minecraft Desktop Pet v1.0.0 · macOS

macOS edition synchronized with the Windows v1.0.0 main release, built as a universal binary for Apple Silicon / Intel: Apple Silicon requires macOS 12+, Intel requires macOS 13+. This release is the mainline standard edition, without the Blockbench compatibility layer.

## Startup & Permissions

Place the complete `Minecraft Desktop Pet.app` (or `Minecraft桌宠.app`) in a fixed location (e.g. `/Applications`) and open it. The menu bar icon allows opening settings, feeding an apple, recentering the pet, and quitting.
Full click-through is enabled by default; disabling "Click-Through" allows dragging the pet, double-clicking opens Settings (unless "Lock double-click" is checked), and right-clicking displays the context menu. You can still feed apples from the menu bar when click-through is enabled.

"Input Permissions…" in the top-right of Settings provides Input Monitoring, Accessibility, re-checking, restart, and input test diagnostics.
Global keyboard interaction requires Input Monitoring; quick chat requires Accessibility permissions. Updating ad-hoc signed builds may require reauthorizing.

Permission indicators: green when both are satisfied, yellow when only one is granted, red when neither is granted. Clicking "Request Input Monitoring" or "Request Accessibility" opens the corresponding System Settings list and shows an application icon card; drag the card into the list and toggle the switch on. If System Settings shows granted but the pet only types inside this app's windows, delete the old entry ("−") and drag the card in again, then restart.

Typing `#` automatically fills `/p chat ` (with a trailing space) without sending or touching the clipboard.

The software does not record or upload typed text. Secure text input (such as password fields) temporarily pauses global keyboard listening.

## Three-Page Native Settings Console

- **General**: Skin and cape, posture, arms, main hand mapping, all interaction toggles, frame rate, scale, chibi proportion, and login autostart.
- **Look & Rotation**: Head tracking, sensitivity, range, center offset, and overall X/Y/Z model rotation.
- **Custom Pose**: Select standing or sitting to edit X/Y/Z angles for six body parts. Standing and sitting poses are saved independently.

Settings are saved automatically; closing the settings panel only closes the window. Light and dark modes follow macOS system appearance. "Reset Skin" only resets the skin; "Reset Defaults" resets all settings.

## v1.0.0 Interactions

- **DA Blink**: Requires custom skin with eye textures and markers. Automatically disabled in Chibi mode.
- **DA Dance**: Automatically sneaks and sways in standard standing posture without holding Shift; sitting and custom poses do not trigger.
- **Chibi Character**: Head size is preserved; "Chibi Body Scale" scales torso and limbs.
- **Four Main Hands**: Right hand, left hand, physical map, inverted map.
- **Feed Apple**: Triggered via menu bar or right-click menu; adapts to standing, sitting, and chibi postures.
- **Typing Letters**: Keystroke positions float candy-colored letters that fade out in 0.8s. Uses native macOS bold typography.
- **Music Notes**: Displays notes during active playback in supported players (Apple Music, Spotify, Netease Cloud Music, QQ Music). Reads process audio session flags via Core Audio without recording audio or inspecting track content.
- **Interactable**: Clicking visible areas shakes head or swings arms. Holding left click for 0.5s triggers head patting.
- **PAT Meow!**: Hand appears to pat the head with random meow sound effects, volume controlled by "Sound Volume".
- **Keyboard Style & Color**: At bottom of "Custom Pose", choose Simple or Detailed style, and customize 6-digit hex color.
- **Breathing**: Subtle continuous breathing animation.

## Skins & Capes

Import 64×64, 64×32, or high-res PNG skins (up to 1024×1024, 8 MB), or enter a Java Edition username / UUID to download official skins and capes.
Imported files are copied to the application data directory:
`~/Library/Application Support/MinecraftDesktopPet-macOS/`

## Login Startup & Updates

Login startup registers a user LaunchAgent.
"Check Updates" queries GitHub stable releases, comparing numerical versions.

## Performance

Rust renderer with lightweight AppKit UI. Reuses pixel buffers and uses lightweight lookup tables for HD skins.
Adjustable frame rate ceiling to minimize CPU usage; pauses rendering when idle or hidden.

Independent fan work; not affiliated with Mojang Studios or Microsoft.
