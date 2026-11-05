import AppKit

/// One settings value carried by a menu item, so radio-style submenus share one action.
final class MenuSetting: NSObject {
    let key: String, value: Any
    init(_ key: String, _ value: Any) { self.key = key; self.value = value }
}

/// Pet right-click menu and status-bar menu share the Windows 2.5.2 layout:
/// same-kind options live in submenus whose title shows the current value.
/// The frame timer runs in `.common` mode, so the pet keeps animating while a menu tracks.
extension AppDelegate {
    func buildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        add(menu, "Open Settings…", #selector(showSettings), key: ",")
        if startupPending {
            add(menu, "Exit Minecraft Desktop Pet", #selector(quit), key: "q")
            return
        }
        let actions = submenu(menu, "Gestures")
        for (index, title) in ["Wave", "Jump", "Shy", "Clap"].enumerated() {
            add(actions, title, #selector(triggerGesture(_:))).tag = index
        }
        add(actions, "Feed Apple", #selector(feedApple))
        menu.addItem(.separator())
        let posture = settings["posture"] as? String ?? "standing"
        let postureNames = ["standing": "Standing", "sitting": "Sitting", "custom": "Custom Pose"]
        choices(submenu(menu, "Pose: \(postureNames[posture] ?? "Standing")"), "posture",
                [("Standing", "standing"), ("Sitting", "sitting"), ("Custom Pose", "custom")])
        let look = submenu(menu, "Appearance")
        add(look, "Import PNG Skin…", #selector(importSkin))
        look.addItem(.separator())
        choices(look, "armModel", [("Classic Arms", "classic"), ("Slim Arms", "slim")])
        look.addItem(.separator())
        toggle(look, "Show Cape", "showCape")
        toggle(look, "Chibi", "chibi")
        let scale = number("scale")
        let sizes = submenu(menu, "Scale: \(Int((scale * 100).rounded()))%")
        for value in [0.75, 1.0, 1.25, 1.5] {
            let item = add(sizes, "\(Int(value * 100))%", #selector(menuChoice(_:)), state: abs(scale - value) < 0.001)
            item.representedObject = MenuSetting("scale", value)
        }
        let hand = settings["mainHand"] as? String ?? "right"
        let handNames = ["right": "Right Hand", "left": "Left Hand", "mapped": "Physical Map", "reverse": "Inverted Map"]
        choices(submenu(menu, "Mouse Wave: \(handNames[hand] ?? "Right Hand")"), "mainHand",
                [("Right Hand", "right"), ("Left Hand", "left"), ("Physical Map", "mapped"), ("Inverted Map", "reverse")])
        let typing = !flag("keyboardEnabled") ? "Disabled"
            : settings["typingMode"] as? String == "alternating" ? "Alternating" : "Precise"
        let keys = submenu(menu, "Keyboard: \(typing)")
        toggle(keys, "Keyboard Interaction", "keyboardEnabled")
        keys.addItem(.separator())
        choices(keys, "typingMode", [("Precise", "precise"), ("Alternating", "alternating")])
        keys.addItem(.separator())
        add(keys, "hyp quick chat: # → /p chat", #selector(toggleQuickChat), state: flag("hypQuickChat"))
        add(keys, "Request Input Monitoring…", #selector(grantInput))
        add(keys, "Request Accessibility (Quick Chat)…", #selector(grantAccessibility))
        menu.addItem(.separator())
        toggle(menu, "Always on Top", "alwaysOnTop")
        toggle(menu, "Click-Through", "clickThrough")
        toggle(menu, "Track Mouse", "trackMouse")
        let desk = submenu(menu, "Desktop & Startup")
        add(desk, "Center on Screen", #selector(recenter))
        add(desk, hidden ? "Show Pet" : "Hide Pet", #selector(toggleHidden))
        desk.addItem(.separator())
        toggle(desk, "Start with macOS", "autostart")
        menu.addItem(.separator())
        add(menu, "Exit Minecraft Desktop Pet", #selector(quit), key: "q")
    }
    func menuWillOpen(_ menu: NSMenu) { buildMenu(menu); menuOpen = true; updateHold() }
    func menuDidClose(_ menu: NSMenu) { menuOpen = false }
    func showPetMenu(_ event: NSEvent, in view: NSView) {
        let menu = NSMenu(); buildMenu(menu)
        menuOpen = true; updateHold()
        NSMenu.popUpContextMenu(menu, with: event, for: view)
        menuOpen = false
    }
    @discardableResult
    private func add(_ menu: NSMenu, _ title: String, _ action: Selector, state: Bool? = nil, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key); item.target = self
        if let state { item.state = state ? .on : .off }
        menu.addItem(item); return item
    }
    private func submenu(_ menu: NSMenu, _ title: String) -> NSMenu {
        let child = NSMenu(title: title), item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = child; menu.addItem(item); return child
    }
    private func toggle(_ menu: NSMenu, _ title: String, _ key: String) {
        add(menu, title, #selector(menuToggle(_:)), state: flag(key)).representedObject = key
    }
    private func choices(_ menu: NSMenu, _ key: String, _ options: [(String, String)]) {
        let current = settings[key] as? String
        for (title, value) in options {
            add(menu, title, #selector(menuChoice(_:)), state: current == value).representedObject = MenuSetting(key, value)
        }
    }
    @objc func menuChoice(_ sender: NSMenuItem) {
        guard let choice = sender.representedObject as? MenuSetting else { return }
        applyMenuSetting(choice.key, choice.value)
    }
    /// Flips the value at click time, so a menu item never writes a stale state.
    @objc func menuToggle(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        applyMenuSetting(key, !flag(key))
    }
    /// Same side effects as the matching console control.
    func applyMenuSetting(_ key: String, _ value: Any) {
        let previous = settings[key]
        settings[key] = value
        if key == "autostart" {
            do { if !smoke { try syncLoginStartup() } }
            catch { settings[key] = previous; alert(error.localizedDescription); return }
        }
        changed()
        if key == "autostart" || key == "keyboardEnabled" { save() }
        if key == "keyboardEnabled" {
            configureInput()
            if !smoke && flag("keyboardEnabled") && !input.running { grantInput() }
        }
        refreshConsoleControls()
    }
    @objc func triggerGesture(_ sender: NSMenuItem) {
        guard core != nil, pet_gesture(core, UInt32(clamping: sender.tag), now) else { return }
        wake()
    }
}
