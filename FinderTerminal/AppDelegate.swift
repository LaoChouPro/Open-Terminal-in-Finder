import Cocoa
import ServiceManagement
import FinderSync

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    private var statusItem: NSStatusItem!
    private var mainMenu: NSMenu!
    private var launchAtLoginItem: NSMenuItem!
    private var extStatusItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupURLEventHandler()
        NSLog("[FinderTerminalHost] App successfully initialized.")
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            if let image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "访达右键终端") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = ">_"
            }
            button.toolTip = "访达右键终端 (FinderTerminal)"
        }
        
        mainMenu = NSMenu()
        mainMenu.autoenablesItems = false
        mainMenu.delegate = self
        
        // 1. App Title
        let titleItem = NSMenuItem(title: "访达右键终端", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        mainMenu.addItem(titleItem)
        
        // 2. Extension Status
        extStatusItem = NSMenuItem(title: "● 检查访达扩展状态...", action: nil, keyEquivalent: "")
        extStatusItem.isEnabled = false
        mainMenu.addItem(extStatusItem)
        
        mainMenu.addItem(NSMenuItem.separator())
        
        // 3. Launch At Login
        launchAtLoginItem = NSMenuItem(
            title: "开机自启动",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        mainMenu.addItem(launchAtLoginItem)
        
        // 4. Open Extension Settings
        let extPrefItem = NSMenuItem(
            title: "打开系统扩展设置...",
            action: #selector(openExtensionSettings(_:)),
            keyEquivalent: ""
        )
        extPrefItem.target = self
        mainMenu.addItem(extPrefItem)
        
        // 5. Restart Finder
        let restartFinderItem = NSMenuItem(
            title: "重启访达以刷新扩展",
            action: #selector(restartFinder(_:)),
            keyEquivalent: "r"
        )
        restartFinderItem.target = self
        mainMenu.addItem(restartFinderItem)
        
        mainMenu.addItem(NSMenuItem.separator())
        
        // 6. Convenience action
        let openHomeItem = NSMenuItem(
            title: "在终端中打开个人目录",
            action: #selector(openHomeInTerminal(_:)),
            keyEquivalent: "t"
        )
        openHomeItem.target = self
        mainMenu.addItem(openHomeItem)
        
        mainMenu.addItem(NSMenuItem.separator())
        
        // 7. Quit
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        mainMenu.addItem(quitItem)
        
        statusItem.menu = mainMenu
        updateMenuStates()
    }
    
    // NSMenuDelegate: Refresh status whenever menu is clicked
    func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenuStates()
    }
    
    private func updateMenuStates() {
        launchAtLoginItem.state = LaunchAtLogin.shared.isEnabled ? .on : .off
        let active = isExtensionActive()
        extStatusItem.title = active ? "● 访达右键扩展已启用" : "○ 访达右键扩展待启用"
    }
    
    // MARK: - URL Handling (Custom URL Scheme IPC)
    
    private func setupURLEventHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else { return }
        handleIncomingURL(url)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleIncomingURL(url)
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "finderterminal" else { return }
        
        var targetPath: String? = nil
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let items = components.queryItems {
            targetPath = items.first(where: { $0.name == "path" })?.value
        }
        
        openTerminal(at: targetPath)
    }
    
    func openTerminal(at targetPath: String?) {
        var path = targetPath ?? ""
        if !path.isEmpty {
            path = (path as NSString).standardizingPath
        }
        if path.isEmpty || !FileManager.default.fileExists(atPath: path) {
            path = FileManager.default.homeDirectoryForCurrentUser.path
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        do {
            try process.run()
            NSLog("[FinderTerminalHost] Opened Terminal at: \(path)")
        } catch {
            NSLog("[FinderTerminalHost] Failed to execute open: \(error)")
        }
    }
    
    // MARK: - Menu Actions
    
    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = !LaunchAtLogin.shared.isEnabled
        LaunchAtLogin.shared.isEnabled = newState
        sender.state = newState ? .on : .off
    }
    
    @objc private func openExtensionSettings(_ sender: Any?) {
        FIFinderSyncController.showExtensionManagementInterface()
    }
    
    @objc private func restartFinder(_ sender: Any?) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        task.arguments = ["Finder"]
        try? task.run()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateMenuStates()
        }
    }
    
    @objc private func openHomeInTerminal(_ sender: Any?) {
        openTerminal(at: FileManager.default.homeDirectoryForCurrentUser.path)
    }
    
    @objc private func quitApp(_ sender: Any?) {
        NSApp.terminate(nil)
    }
    
    private func isExtensionActive() -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-m", "-p", "com.apple.FinderSync"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try? task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let str = String(data: data, encoding: .utf8) {
            return str.contains("com.vibe.FinderTerminal.Extension")
        }
        return false
    }
}
