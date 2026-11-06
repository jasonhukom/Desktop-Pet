import AppKit
import UniformTypeIdentifiers

enum ConsoleSize {
    // 2.5.3 adds one row (PAT Meow! on General, keyboard style on Custom Pose), +36 like Windows.
    static let design = NSSize(width: 760, height: 816)
    static let compact = NSSize(width: 646, height: 694)
    static let page = NSSize(width: 712, height: 632)
}

extension AppDelegate {
    @objc func showSettings() {
        guard core != nil else { return }
        if startupPending { finishStartup() }
        if let panel { panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let w = consoleWindow ?? NSWindow(contentRect: NSRect(origin: .zero, size: ConsoleSize.compact),
            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        consoleWindow = w
        w.setContentSize(ConsoleSize.compact)
        w.contentView = NSView(frame: NSRect(origin: .zero, size: ConsoleSize.compact))
        w.title = "Minecraft Desktop Pet · v\(appVersion) · Settings"
        w.isReleasedWhenClosed = false; w.isRestorable = false; w.delegate = self
        let root = w.contentView!
        // Scale the existing layout as one view, including native hit testing.
        root.setBoundsSize(ConsoleSize.design)
        for (index, title) in ["General", "Look & Rotation", "Custom Pose"].enumerated() {
            let button = NSButton(title: title, target: self, action: #selector(selectConsolePage(_:)))
            button.setButtonType(.pushOnPushOff); button.bezelStyle = .regularSquare
            button.font = .systemFont(ofSize: 15, weight: .medium); button.tag = index
            button.frame = NSRect(x: 24 + index * 224, y: 764, width: 216, height: 34)
            button.setAccessibilityLabel(title); root.addSubview(button); pageButtons.append(button)
        }
        let langBtn = NSButton(title: "🌐", target: self, action: #selector(showLanguageMenu(_:)))
        langBtn.bezelStyle = .regularSquare
        langBtn.font = .systemFont(ofSize: 16)
        langBtn.frame = NSRect(x: 696, y: 760, width: 40, height: 32)
        langBtn.setAccessibilityLabel("Language")
        root.addSubview(langBtn)
        let tabs = NSTabView(frame: NSRect(origin: NSPoint(x: 24, y: 114), size: ConsoleSize.page))
        tabs.tabViewType = .noTabsNoBorder
        for title in ["General", "Look & Rotation", "Custom Pose"] {
            let item = NSTabViewItem(identifier: title); item.label = title; tabs.addTabViewItem(item)
        }
        root.addSubview(tabs); controlTabs = tabs; panel = w; tabs.delegate = self
        uiReady = false; tabs.selectTabViewItem(at: min(selectedConsolePage, 2)); uiReady = true
        populatePage(min(selectedConsolePage, 2))
        action(root, "Check Updates", #selector(checkUpdates), 20, 70, 112)
        action(root, "Input Permissions…", #selector(showPermissions), 140, 70, 140)
        action(root, "Reset Defaults…", #selector(confirmReset), 288, 70, 120)
        let github = action(root, "GitHub", #selector(openProject), 614, 70, 126)
        if let url = Bundle.main.url(forResource: "github", withExtension: "svg"), let icon = NSImage(contentsOf: url) {
            icon.size = NSSize(width: 18, height: 18); icon.isTemplate = true
            github.image = icon; github.imagePosition = .imageLeading
        }
        github.setAccessibilityLabel("GitHub Project Page")
        // Footer control: page bindings are cleared on every page switch, so it has its own action.
        let lock = NSButton(checkboxWithTitle: "Lock double-click (double-click won't open settings)", target: self, action: #selector(toggleLockDoubleClick(_:)))
        lock.font = .systemFont(ofSize: 11); lock.state = flag("lockDoubleClick") ? .on : .off
        lock.frame = NSRect(x: 416, y: 72, width: 194, height: 24)
        root.addSubview(lock); lockDoubleClickBox = lock
        saveStatus = label(root, "Saved", 24, 43, 80)
        permissionSummary = label(root, "", 112, 43, 420)
        permissionSummary?.font = .systemFont(ofSize: 11); permissionSummary?.textColor = .secondaryLabelColor
        label(root, "Drag to move · Right-click for menu · Double-click for settings; closing this window will not exit the pet.", 24, 16, 712).textColor = .secondaryLabelColor
        updatePermission(); w.center(); w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
    }
    func refreshConsoleControls() {
        guard panel != nil, controlTabs != nil else { return }
        lockDoubleClickBox?.state = flag("lockDoubleClick") ? .on : .off
        populatePage(selectedConsolePage)
    }
    @objc func toggleLockDoubleClick(_ sender: NSButton) {
        settings["lockDoubleClick"] = sender.state == .on; changed()
    }
    @objc func selectConsolePage(_ sender: NSButton) {
        // Selecting the current tab does not call NSTabViewDelegate again.
        // Keep its push-on/off button selected instead of leaving all tabs off.
        guard sender.tag != selectedConsolePage else { sender.state = .on; return }
        controlTabs?.selectTabViewItem(at: sender.tag)
    }
    func releaseConsole() {
        uiReady = false; bindings.removeAll(); pageButtons.removeAll(); saveStatus = nil
        controlTabs = nil; panel = nil
        permissionSummary = nil; lockDoubleClickBox = nil; skinSummary = nil; onlineField = nil; onlineStatus = nil; keyboardColorField = nil
        permissionLabel = nil; startupStatus = nil; musicToggle = nil
        consoleWindow?.contentView = NSView(frame: NSRect(origin: .zero, size: ConsoleSize.compact))
    }
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === guidePanel { closeGuide() }
        if window === panel {
            closePermissions(); save(); selectedConsolePage = controlTabs?.indexOfTabViewItem(controlTabs!.selectedTabViewItem!) ?? 0
            releaseConsole()
        }
    }
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        guard uiReady, let item = tabViewItem else { return }
        populatePage(tabView.indexOfTabViewItem(item))
    }
    func populatePage(_ index: Int) {
        guard let tabs = controlTabs else { return }
        bindings.removeAll(); skinSummary = nil; onlineField = nil; onlineStatus = nil; keyboardColorField = nil; musicToggle = nil
        for (i, item) in tabs.tabViewItems.enumerated() where i != index { item.view = NSView() }
        selectedConsolePage = index
        for button in pageButtons { button.state = button.tag == index ? .on : .off }
        let content = NSView(frame: NSRect(origin: .zero, size: ConsoleSize.page))
        tabs.tabViewItems[index].view = content
        switch index {
        case 1: addHead(content); raise(content, above: 0)
        case 2: addPose(content); raise(content, above: 0); addKeyboardLook(content)
        default: addGeneral(content); raise(content, above: 60); addPat(content)
        }
    }
    /// The pages were laid out for the 2.5.2 height; lift rows to free the new 36-point row.
    func raise(_ view: NSView, above y: CGFloat) {
        for sub in view.subviews where sub.frame.minY >= y { sub.frame.origin.y += 36 }
    }
    /// General row added in 2.5.3, between Chibi Body Scale and Other (as on Windows).
    func addPat(_ view: NSView) {
        label(view, "Sound Volume", 0, 71, 110)
        check(view, "PAT Meow!", "patEnabled", 126, 68, 110)
        let current = value("patVolume")
        let output = label(view, displayValue("patVolume", current), 626, 71, 86)
        output.alignment = .right; output.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        let slider = NSSlider(value: current, minValue: 0, maxValue: 100, target: self, action: #selector(controlChanged(_:)))
        slider.frame = NSRect(x: 256, y: 68, width: 354, height: 24); slider.isContinuous = true
        slider.setAccessibilityLabel("Sound Volume")
        bindings[ObjectIdentifier(slider)] = Binding("patVolume", [], output); view.addSubview(slider)
    }
    /// Custom Pose row added in 2.5.3: keyboard style, and the colour moved here from General.
    func addKeyboardLook(_ view: NSView) {
        label(view, "Keyboard Style", 0, 5, 110)
        radios(view, "keyboardStyle", ["Simple", "Detailed"], ["simple", "detailed"], 126, 2, 130)
        label(view, "Keyboard Color", 366, 5, 110)
        let color = NSTextField(frame: NSRect(x: 486, y: 1, width: 116, height: 25))
        color.stringValue = settings["keyboardColor"] as? String ?? "#83878A"; color.placeholderString = "#83878A"
        color.target = self; color.action = #selector(applyKeyboardColor); color.setAccessibilityLabel("Keyboard Color")
        view.addSubview(color); keyboardColorField = color
        action(view, "✓", #selector(applyKeyboardColor), 610, -1, 42).setAccessibilityLabel("Apply Keyboard Color")
    }
    @discardableResult
    func label(_ view: NSView, _ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat = 20) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: 13)
        l.frame = NSRect(x: x, y: y, width: width, height: height)
        view.addSubview(l); return l
    }
    @discardableResult
    func action(_ view: NSView, _ title: String, _ selector: Selector, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat) -> NSButton {
        let b = NSButton(title: title, target: self, action: selector); b.bezelStyle = .rounded
        b.frame = NSRect(x: x, y: y, width: width, height: 28); view.addSubview(b); return b
    }
    func check(_ view: NSView, _ title: String, _ key: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 290) {
        let b = NSButton(checkboxWithTitle: title, target: self, action: #selector(controlChanged(_:)))
        b.font = .systemFont(ofSize: 13); b.state = flag(key) ? .on : .off
        b.frame = NSRect(x: x, y: y, width: width, height: 24)
        if key == "daBlink" { b.toolTip = "Requires custom modified skin." }
        if key == "musicNotes" { musicToggle = b; refreshMusicLabel() }
        bindings[ObjectIdentifier(b)] = Binding(key); view.addSubview(b)
    }
    /// Same rule as the Windows console and `normalize_keyboard_color`: six hex digits, optional #.
    static func normalizedKeyboardColor(_ text: String) -> String? {
        var hex = text.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, hex.allSatisfy(\.isHexDigit) else { return nil }
        return "#" + hex.uppercased()
    }
    @objc func applyKeyboardColor() {
        guard let field = keyboardColorField else { return }
        guard let color = Self.normalizedKeyboardColor(field.stringValue) else {
            field.stringValue = settings["keyboardColor"] as? String ?? "#83878A"
            if !smoke { alert("Please enter a 6-digit hex color code, e.g. #83878A.") }
            return
        }
        field.stringValue = color; settings["keyboardColor"] = color; changed()
    }
    func popup(_ view: NSView, _ title: String, _ key: String, _ names: [String], _ values: [Any],
               _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 290) {
        label(view, title, x, y + 4, 88)
        let b = NSPopUpButton(frame: NSRect(x: x + 90, y: y, width: width - 90, height: 28), pullsDown: false)
        b.addItems(withTitles: names)
        let current = String(describing: settings[key] ?? "")
        if let i = values.firstIndex(where: { String(describing: $0) == current }) { b.selectItem(at: i) }
        b.target = self; b.action = #selector(controlChanged(_:))
        bindings[ObjectIdentifier(b)] = Binding(key, values); view.addSubview(b)
    }
    func radios(_ view: NSView, _ key: String, _ names: [String], _ choices: [String],
                _ x: CGFloat, _ y: CGFloat, _ step: CGFloat) {
        // Each row has its own container so AppKit's native radio grouping does
        // not deselect unrelated rows. The selected value stays in the binding.
        let group = NSView(frame: NSRect(x: x, y: y, width: step * CGFloat(names.count), height: 24))
        view.addSubview(group)
        for (index, title) in names.enumerated() {
            let button = NSButton(radioButtonWithTitle: title, target: self, action: #selector(controlChanged(_:)))
            button.frame = NSRect(x: CGFloat(index) * step, y: 0, width: step - 2, height: 24)
            button.font = .systemFont(ofSize: 13)
            button.state = settings[key] as? String == choices[index] ? .on : .off
            button.setAccessibilityLabel(title)
            bindings[ObjectIdentifier(button)] = Binding(key, [choices[index]])
            group.addSubview(button)
        }
    }
    func displayValue(_ key: String, _ value: Double) -> String {
        switch key {
        case "scale": return String(format: "%.0f%%", value * 100)
        case "typingSquash", "chibiBodyScale", "patVolume": return String(format: "%.0f%%", value)
        case "fps": return "\(Int(value)) FPS"
        default: return String(format: "%.1f", value)
        }
    }
    func syncRadioStates(_ view: NSView) {
        if let button = view as? NSButton,
           let binding = bindings[ObjectIdentifier(button)], let choice = binding.choices.first as? String {
            button.state = settings[binding.key] as? String == choice ? .on : .off
        }
        for child in view.subviews { syncRadioStates(child) }
    }
    func generalSlider(_ view: NSView, _ title: String, _ key: String, _ lower: Double,
                       _ upper: Double, _ y: CGFloat, choices: [Int] = []) {
        label(view, title, 0, y + 3, 120)
        let current = value(key)
        let output = label(view, displayValue(key, current), 626, y + 3, 86)
        output.alignment = .right; output.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        let index = choices.firstIndex(of: Int(current)) ?? 0
        let slider = NSSlider(value: choices.isEmpty ? current : Double(index), minValue: lower,
            maxValue: upper, target: self, action: #selector(controlChanged(_:)))
        slider.frame = NSRect(x: 126, y: y, width: 484, height: 24); slider.isContinuous = true
        slider.setAccessibilityLabel(title)
        if !choices.isEmpty { slider.numberOfTickMarks = choices.count; slider.allowsTickMarkValuesOnly = true }
        bindings[ObjectIdentifier(slider)] = Binding(key, choices.map { $0 as Any }, output)
        view.addSubview(slider)
    }
    func value(_ key: String) -> Double {
        let p = key.split(separator: ".").map(String.init)
        if p.count == 1 { return number(key) }
        if p.count == 2, let i = Int(p[1]), let list = settings[p[0]] as? [Double], list.indices.contains(i) { return list[i] }
        if p.count == 3, let i = Int(p[2]), let dict = settings[p[0]] as? [String: Any], let list = dict[p[1]] as? [Double], list.indices.contains(i) { return list[i] }
        return 0
    }
    func setValue(_ key: String, _ value: Double) {
        let p = key.split(separator: ".").map(String.init)
        // Integer settings (u32 in the core) must not be written as fractions.
        if key == "patVolume" { settings[key] = Int(value.rounded()) }
        else if p.count == 1 { settings[key] = value }
        else if p.count == 2, let i = Int(p[1]), var list = settings[p[0]] as? [Double], list.indices.contains(i) { list[i] = value; settings[p[0]] = list }
        else if p.count == 3, let i = Int(p[2]), var dict = settings[p[0]] as? [String: Any], var list = dict[p[1]] as? [Double], list.indices.contains(i) {
            list[i] = value; dict[p[1]] = list; settings[p[0]] = dict
        }
    }
    func slider(_ view: NSView, _ title: String, _ key: String, _ min: Double, _ max: Double,
                _ x: CGFloat, _ y: CGFloat, _ width: CGFloat = 590) {
        label(view, title, x, y + 3, 110)
        let v = value(key), out = label(view, String(format: "%.1f", value(key)), x + width - 45, y + 3, 45)
        out.alignment = .right; out.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let s = NSSlider(value: v, minValue: min, maxValue: max, target: self, action: #selector(controlChanged(_:)))
        s.frame = NSRect(x: x + 114, y: y, width: width - 168, height: 24)
        s.isContinuous = true; bindings[ObjectIdentifier(s)] = Binding(key, [], out); view.addSubview(s)
    }
    @objc func controlChanged(_ sender: NSControl) {
        guard let b = bindings[ObjectIdentifier(sender)] else { return }
        if let s = sender as? NSSlider {
            let v: Double
            if !b.choices.isEmpty {
                let index = min(b.choices.count - 1, max(0, Int(s.doubleValue.rounded())))
                v = (b.choices[index] as? NSNumber)?.doubleValue ?? s.doubleValue
            } else { v = s.doubleValue }
            setValue(b.key, v); b.label?.stringValue = displayValue(b.key, v)
        }
        else if let p = sender as? NSPopUpButton, b.choices.indices.contains(p.indexOfSelectedItem) { settings[b.key] = b.choices[p.indexOfSelectedItem] }
        else if let c = sender as? NSButton {
            if let choice = b.choices.first {
                settings[b.key] = choice
                for peer in c.superview?.subviews.compactMap({ $0 as? NSButton }) ?? [] {
                    peer.state = peer === c ? .on : .off
                }
            } else { settings[b.key] = c.state == .on }
        }
        if b.key == "autostart" {
            do { if !smoke { try syncLoginStartup() } }
            catch { loadSettings(); (sender as? NSButton)?.state = flag("autostart") ? .on : .off; alert(error.localizedDescription); return }
        }
        if b.key.hasPrefix("custom") { settings["posture"] = "custom" }
        if let page = controlTabs?.selectedTabViewItem?.view { syncRadioStates(page) }
        if b.key == "typingLetters" && flag("typingLetters") { prepareGlyphs() }
        changed()
        if b.key == "autostart" { save() }
        if b.key == "musicNotes" { configureMusic() }
        if b.key == "keyboardEnabled" || b.key == "hypQuickChat" {
            save(); configureInput()
            if !smoke && b.key == "keyboardEnabled" && flag("keyboardEnabled") && !input.running { grantInput() }
            if !smoke && b.key == "hypQuickChat" && flag("hypQuickChat") && !input.accessibilityAllowed { grantAccessibility() }
        }
        if b.key == "customBase" || b.key == "chibi" { populatePage(selectedConsolePage) }
    }
    func addGeneral(_ view: NSView) {
        label(view, "Skin", 0, 551, 110)
        skinSummary = label(view, "", 126, 551, 320); updateSkinSummary()
        skinSummary?.lineBreakMode = .byTruncatingMiddle
        action(view, "Import Skin…", #selector(importSkin), 466, 546, 124)
        action(view, "Reset Skin", #selector(restoreBuiltinSkin), 598, 546, 118)
        label(view, "Original ID", 0, 515, 110)
        let field = NSTextField(frame: NSRect(x: 126, y: 512, width: 334, height: 25))
        field.placeholderString = "Java Edition username or UUID"; view.addSubview(field); onlineField = field
        action(view, "Fetch Skin", #selector(downloadSkin), 466, 509, 124)
        label(view, "No login needed", 596, 515, 116)
        onlineStatus = label(view, "", 126, 488, 586)
        onlineStatus?.font = .systemFont(ofSize: 11); onlineStatus?.textColor = .secondaryLabelColor
        for (title, y) in [("Arms",452),("Appearance",420),("Pose",388),("Typing",356),("Main Hand",324),
                            ("Desktop",292),("Keyboard",260),("Animation",228),("Other",36),("Music",4)] {
            label(view, title, 0, CGFloat(y + 3), 110)
        }
        radios(view, "armModel", ["Classic (4 px)", "Slim (3 px)"], ["classic","slim"], 126, 452, 230)
        check(view, "Show outer layer", "outerLayer", 126, 420, 260)
        check(view, "Chibi character", "chibi", 478, 420, 210)
        radios(view, "posture", ["Standing","Sitting","Custom"], ["standing","sitting","custom"], 126, 388, 112)
        label(view, "Hold Shift while standing to sneak", 478, 391, 234)
        radios(view, "typingMode", ["Precise","Alternating"], ["precise","alternating"], 126, 356, 230)
        radios(view, "mainHand", ["Right hand","Left hand","Physical map","Inverted map"],
               ["right","left","mapped","reverse"], 126, 324, 146)
        check(view, "Always on top", "alwaysOnTop", 126, 292, 210)
        check(view, "Click-through", "clickThrough", 356, 292, 220)
        action(view, "Recenter", #selector(recenter), 598, 289, 118)
        check(view, "Keyboard interaction", "keyboardEnabled", 126, 260, 220)
        check(view, "hyp quick team chat", "hypQuickChat", 356, 260, 220)
        label(view, "# → /p chat", 594, 263, 118)
        check(view, "DA blink (custom skin)", "daBlink", 126, 228, 230)
        check(view, "DA dance", "daDance", 360, 228, 100)
        check(view, "Typing letters", "typingLetters", 464, 228, 124)
        check(view, "Interactable", "teaseEnabled", 592, 228, 120)
        check(view, "Breathing", "idleAnimation", 126, 196, 120)
        check(view, "Stretch", "occasionalStretch", 250, 196, 140)
        check(view, "Tilt head", "occasionalTilt", 394, 196, 130)
        check(view, "Sleepy", "occasionalSleepy", 528, 196, 140)
        generalSlider(view, "Scale", "scale", 0.65, 1.8, 164)
        generalSlider(view, "Frame Rate", "fps", 0, 6, 132, choices: [30,60,90,120,144,165,240])
        generalSlider(view, "Typing Squash", "typingSquash", 0, 30, 100)
        generalSlider(view, "Chibi Body Scale", "chibiBodyScale", 50, 180, 68)
        check(view, "Show Cape", "showCape", 126, 36, 260)
        check(view, "Start with macOS", "autostart", 412, 36, 300)
        check(view, "Music note particles", "musicNotes", 126, 4, 280)
        popup(view, "Startup Delay", "autostartDelay", ["Immediate","5s","15s","30s","60s","120s"],
              LoginStartup.delays, 412, 1, 300)
    }
    func addHead(_ view: NSView) {
        label(view, "Model Orientation & Rotation", 0, 552, 300)
        action(view, "Reset Rotation", #selector(resetRotation), 598, 546, 118)
        for (i, title) in ["Pitch · X","Yaw · Y","Roll · Z"].enumerated() {
            generalSlider(view, title, "modelRotation.\(i)", -180, 180, CGFloat(500 - i * 43))
        }
        check(view, "Track mouse cursor", "trackMouse", 0, 350, 300)
        action(view, "Reset Tracking", #selector(resetHead), 598, 346, 118)
        for (x, axis, title) in [(CGFloat(0), "X", "Horizontal (X)"), (CGFloat(380), "Y", "Vertical (Y)")] {
            label(view, title, x, 310, 332)
            for (row, entry) in [("Sensitivity", "headSensitivity", 0.0, 300.0),
                                 ("Range", "headRange", 0.0, 85.0),
                                 ("Center Offset", "headCenter", -60.0, 60.0)].enumerated() {
                let y = CGFloat(264 - row * 65), key = entry.1 + axis
                label(view, entry.0, x, y, 200)
                let out = label(view, displayValue(key, value(key)), x + 244, y, 88); out.alignment = .right
                let slider = NSSlider(value: value(key), minValue: entry.2, maxValue: entry.3,
                    target: self, action: #selector(controlChanged(_:)))
                slider.frame = NSRect(x: x, y: y - 28, width: 332, height: 24); slider.isContinuous = true
                slider.setAccessibilityLabel(title + " · " + entry.0)
                bindings[ObjectIdentifier(slider)] = Binding(key, [], out); view.addSubview(slider)
            }
        }
        label(view, "Negative leans left, positive leans right", 0, 60, 332).textColor = .secondaryLabelColor
        label(view, "Negative looks up, positive looks down", 380, 60, 332).textColor = .secondaryLabelColor
    }
    func addPose(_ view: NSView) {
        radios(view, "posture", ["Use custom pose"], ["custom"], 0, 548, 245)
        radios(view, "customBase", ["Standing","Sitting"], ["standing","sitting"], 266, 548, 116)
        action(view, "Reset Pose", #selector(resetPose), 598, 546, 118)
        label(view, "Standing and sitting poses are saved separately; sitting angles adjust upon default sit pose.", 0, 508, 712)
        for (i, axis) in ["Pitch · X", "Yaw · Y", "Roll · Z"].enumerated() {
            label(view, axis, CGFloat(98 + i * 205), 460, 200).alignment = .center
        }
        let key = settings["customBase"] as? String == "sitting" ? "customSittingPose" : "customPose"
        for (i, part) in [("head","Head"),("body","Body"),("leftArm","Left Arm"),("rightArm","Right Arm"),("leftLeg","Left Leg"),("rightLeg","Right Leg")].enumerated() {
            let y = CGFloat(409 - i * 54); label(view, part.1, 0, y + 3, 85)
            for axis in 0..<3 {
                let x = CGFloat(98 + axis * 205), path = "\(key).\(part.0).\(axis)"
                let out = label(view, displayValue(path, value(path)), x + 142, y + 3, 58)
                out.alignment = .right; out.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
                let slider = NSSlider(value: value(path), minValue: -180, maxValue: 180,
                    target: self, action: #selector(controlChanged(_:)))
                slider.frame = NSRect(x: x, y: y, width: 136, height: 24); slider.isContinuous = true
                slider.setAccessibilityLabel(part.1 + " " + ["X","Y","Z"][axis])
                bindings[ObjectIdentifier(slider)] = Binding(path, [], out); view.addSubview(slider)
            }
        }
        label(view, "Sitting pose supports typing, holding, and waving; returns to set pose afterwards.", 0, 64, 712).textColor = .secondaryLabelColor
        label(view, "Head angles apply when mouse tracking is off; limbs do not bend.", 0, 38, 712).textColor = .secondaryLabelColor
    }
    func syncLoginStartup() throws {
        try LoginStartup.setEnabled(flag("autostart"), app: Bundle.main.bundleURL, data: dataDir, directory: loginDirectory)
    }
    func updateSkinSummary() { skinSummary?.stringValue = settings["skinName"] as? String ?? "Built-in" }
    @objc func importSkin() {
        let p = NSOpenPanel(); p.allowedContentTypes = [.png]; p.allowsMultipleSelection = false; p.canChooseDirectories = false
        NSApp.activate(ignoringOtherApps: true)
        if p.runModal() == .OK, let url = p.url {
            downloadID = UUID(); save()
            guard url.path.withCString({ pet_import(core, $0) }) else { showCoreError(); return }
            loadSettings(); wake(); populatePage(selectedConsolePage)
        }
    }
    @objc func restoreBuiltinSkin() {
        downloadID = UUID(); save()
        guard pet_restore_skin(core) else { showCoreError(); return }
        loadSettings(); updateSkinSummary(); wake()
    }
    @objc func resetHead() {
        for (key, value) in ["headSensitivityX":100.0, "headSensitivityY":100, "headRangeX":19.5,
                             "headRangeY":53, "headCenterX":0, "headCenterY":0] { settings[key] = value }
        changed(); populatePage(1)
    }
    @objc func resetRotation() { settings["modelRotation"] = [0.0,0,0]; changed(); populatePage(1) }
    @objc func resetPose() {
        let key = settings["customBase"] as? String == "sitting" ? "customSittingPose" : "customPose"
        settings[key] = Dictionary(uniqueKeysWithValues: ["head","body","leftArm","rightArm","leftLeg","rightLeg"].map { ($0, [0.0,0,0]) })
        changed(); populatePage(2)
    }
    @objc func confirmReset() {
        let a = NSAlert(); a.messageText = "Reset default settings and built-in skin?"
        a.informativeText = "This will reset pet preferences and disable startup on login; original skin files are kept."
        a.addButton(withTitle: "Cancel"); a.addButton(withTitle: "Reset Defaults")
        if a.runModal() == .alertSecondButtonReturn { resetSettings() }
    }
    @objc func showPermissions() {
        guard permissionPanel == nil else { permissionPanel?.makeKeyAndOrderFront(nil); return }
        let w = NSPanel(contentRect: NSRect(x:0,y:0,width:580,height:270), styleMask:[.titled], backing:.buffered, defer:false)
        w.title = "Input Permissions & Diagnostics"; let root = w.contentView!; permissionPanel = w
        w.titlebarAppearsTransparent = true; w.appearance = NSAppearance(named: .darkAqua)
        let tint = NSView(frame: root.bounds); tint.wantsLayer = true; tint.autoresizingMask = [.width, .height]
        root.addSubview(tint); permissionTint = tint
        accessLabel = label(root, "", 18, 210, 544, 50)
        accessLabel?.lineBreakMode = .byWordWrapping; accessLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        inputRequestButton = action(root, "Request Input Monitoring", #selector(grantInput), 12, 176, 174)
        accessRequestButton = action(root, "Request Accessibility", #selector(grantAccessibility), 194, 176, 174)
        action(root, "Re-check", #selector(refreshPermissions), 380, 176, 178)
        inputHealthLabel = label(root, "", 18, 122, 544, 44); inputHealthLabel?.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        let field = NSTextField(frame:NSRect(x:18,y:83,width:542,height:26)); field.placeholderString = "Type # here to test when quick chat is enabled"; root.addSubview(field); diagnosticsField = field
        action(root, "Restart App", #selector(restartApplication), 12, 24, 142)
        action(root, "Settings Folder", #selector(openDataFolder), 164, 24, 142)
        action(root, "Done", #selector(closePermissions), 438, 24, 120)
        updatePermission()
        if let panel { panel.beginSheet(w) } else { w.center(); w.makeKeyAndOrderFront(nil) }
    }
    @objc func closePermissions() {
        if let w = permissionPanel { w.sheetParent?.endSheet(w); w.orderOut(nil) }
        permissionPanel = nil; permissionTint = nil; accessLabel = nil; inputRequestButton = nil; accessRequestButton = nil
        inputHealthLabel = nil; diagnosticsField = nil
    }
    @objc func previewSwing() { handleMousePress(); wake() }
}

enum LanguageList {
    static let all: [(String, String, String)] = [
        ("en", "English (US)", "English (US)"),
        ("en-GB", "English (UK)", "English (UK)"),
        ("zh-CN", "简体中文", "Simplified Chinese"),
        ("zh-TW", "繁體中文", "Traditional Chinese"),
        ("ja", "日本語", "Japanese"),
        ("ko", "한국어", "Korean"),
        ("es", "Español", "Spanish"),
        ("fr", "Français", "French"),
        ("de", "Deutsch", "German"),
        ("ru", "Русский", "Russian"),
        ("pt-BR", "Português (Brasil)", "Portuguese (Brazil)"),
        ("pt-PT", "Português (Portugal)", "Portuguese (Portugal)"),
        ("it", "Italiano", "Italian"),
        ("nl", "Nederlands", "Dutch"),
        ("pl", "Polski", "Polish"),
        ("tr", "Türkçe", "Turkish"),
        ("ar", "العربية", "Arabic"),
        ("he", "עברית", "Hebrew"),
        ("uk", "Українська", "Ukrainian"),
        ("vi", "Tiếng Việt", "Vietnamese"),
        ("th", "ไทย", "Thai"),
        ("hi", "हिन्दी", "Hindi"),
        ("el", "Ελληνικά", "Greek"),
        ("sv", "Svenska", "Swedish"),
        ("da", "Dansk", "Danish"),
        ("fi", "Suomi", "Finnish"),
        ("nb", "Norsk Bokmål", "Norwegian"),
        ("cs", "Čeština", "Czech"),
        ("hu", "Magyar", "Hungarian"),
        ("ro", "Română", "Romanian"),
        ("bg", "Български", "Bulgarian"),
        ("sk", "Slovenčina", "Slovak"),
        ("hr", "Hrvatski", "Croatian"),
        ("sr", "Српски", "Serbian"),
        ("sl", "Slovenščina", "Slovenian"),
        ("lt", "Lietuvių", "Lithuanian"),
        ("lv", "Latviešu", "Latvian"),
        ("et", "Eesti", "Estonian"),
        ("ca", "Català", "Catalan"),
        ("eu", "Euskara", "Basque"),
        ("gl", "Galego", "Galician"),
        ("fil", "Filipino", "Filipino"),
        ("ms", "Bahasa Melayu", "Malay"),
        ("id", "Bahasa Indonesia", "Indonesian"),
        ("fa", "فارسی", "Persian"),
        ("ur", "اردو", "Urdu"),
        ("bn", "বাংলা", "Bengali"),
        ("ta", "தமிழ்", "Tamil"),
        ("te", "తెలుగు", "Telugu"),
        ("ml", "മലയാളം", "Malayalam"),
        ("kn", "ಕನ್ನಡ", "Kannada"),
        ("mr", "मराठी", "Marathi"),
        ("gu", "ગુજરાતી", "Gujarati"),
        ("pa", "ਪੰਜਾਬੀ", "Punjabi"),
        ("ka", "ქართული", "Georgian"),
        ("hy", "Հայերեն", "Armenian"),
        ("kk", "Қазақша", "Kazakh"),
        ("uz", "O‘zbekcha", "Uzbek"),
        ("mn", "Монгол", "Mongolian"),
        ("az", "Azərbaycanca", "Azerbaijani"),
        ("sw", "Kiswahili", "Swahili"),
        ("af", "Afrikaans", "Afrikaans"),
        ("is", "Íslenska", "Icelandic"),
        ("ga", "Gaeilge", "Irish"),
        ("cy", "Cymraeg", "Welsh"),
        ("mt", "Malti", "Maltese"),
        ("mk", "Македонски", "Macedonian"),
        ("bs", "Bosanski", "Bosnian"),
        ("sq", "Shqip", "Albanian"),
        ("be", "Беларуская", "Belarusian"),
        ("eo", "Esperanto", "Esperanto"),
        ("la", "Latina", "Latin"),
        ("lb", "Lëtzebuergesch", "Luxembourgish"),
        ("fy", "Frysk", "Western Frisian"),
        ("jv", "Basa Jawa", "Javanese"),
        ("su", "Basa Sunda", "Sundanese"),
        ("my", "မြန်မာဘာသာ", "Burmese"),
        ("km", "ភាសាខ្មែរ", "Khmer"),
        ("lo", "ພາສາລາວ", "Lao"),
        ("ne", "नेपाली", "Nepali"),
        ("si", "සිංහල", "Sinhala"),
        ("am", "አማርኛ", "Amharic"),
        ("so", "Soomaali", "Somali"),
        ("haw", "ʻŌlelo Hawaiʻi", "Hawaiian"),
        ("tlh", "tlhIngan Hol", "Klingon"),
    ]
}

extension AppDelegate {
    @objc func showLanguageMenu(_ sender: NSButton) {
        let menu = NSMenu(title: "Language")
        let currentLang = settings["language"] as? String ?? "en"
        let popularCodes = ["en", "zh-CN", "zh-TW", "ja", "ko", "es", "fr", "de", "ru", "pt-BR", "it", "pl", "tr", "ar", "uk", "vi", "th", "hi", "el"]
        for (code, name, eng) in LanguageList.all {
            if popularCodes.contains(code) {
                let item = NSMenuItem(title: "\(name) (\(eng))", action: #selector(selectLanguageItem(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = code
                if code == currentLang { item.state = .on }
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())
        let groups: [(String, [String])] = [
            ("A – C", ["af", "am", "ar", "az", "be", "bg", "bn", "bs", "ca", "cs", "cy"]),
            ("D – F", ["da", "de", "el", "en", "en-GB", "eo", "es", "et", "eu", "fa", "fi", "fil", "fr", "fy"]),
            ("G – J", ["ga", "gl", "gu", "haw", "he", "hi", "hr", "hu", "hy", "id", "is", "it", "ja", "jv"]),
            ("K – N", ["ka", "kk", "km", "kn", "ko", "la", "lb", "lo", "lt", "lv", "mk", "ml", "mn", "mr", "ms", "mt", "my", "nb", "ne", "nl"]),
            ("P – S", ["pa", "pl", "pt-BR", "pt-PT", "ro", "ru", "si", "sk", "sl", "so", "sq", "sr", "su", "sv", "sw"]),
            ("T – Z & Klingon", ["ta", "te", "th", "tlh", "tr", "uk", "ur", "uz", "vi", "zh-CN", "zh-TW"]),
        ]
        for (title, codes) in groups {
            let sub = NSMenu(title: title)
            for code in codes {
                if let entry = LanguageList.all.first(where: { $0.0 == code }) {
                    let item = NSMenuItem(title: "\(entry.1) (\(entry.2))", action: #selector(selectLanguageItem(_:)), keyEquivalent: "")
                    item.target = self
                    item.representedObject = code
                    if code == currentLang { item.state = .on }
                    sub.addItem(item)
                }
            }
            let parentItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            parentItem.submenu = sub
            menu.addItem(parentItem)
        }
        let location = NSPoint(x: 0, y: sender.bounds.height)
        menu.popUp(positioning: nil, at: location, in: sender)
    }
    @objc func selectLanguageItem(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        settings["language"] = code
        changed()
        save()
        panel?.close()
        panel = nil
        showSettings()
    }
}
