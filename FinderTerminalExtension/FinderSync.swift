import Cocoa
import FinderSync

@_silgen_name("NSExtensionMain")
func NSExtensionMain(_ argc: Int32, _ argv: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> Int32

@objc(FinderSync)
class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        NSLog("[FinderTerminalExtension] Initializing FinderSync extension...")
        
        // Monitor root and all mounted volumes so right-click is supported everywhere
        let controller = FIFinderSyncController.default()
        var monitoredURLs = Set<URL>([URL(fileURLWithPath: "/")])
        if let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            monitoredURLs.formUnion(volumes)
        }
        controller.directoryURLs = monitoredURLs
        
        // Monitor newly mounted volumes dynamically
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let volumeURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                var current = controller.directoryURLs ?? Set<URL>()
                current.insert(volumeURL)
                controller.directoryURLs = current
            }
        }
    }
    
    // MARK: - Menu Provider
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForItems:
            let menu = NSMenu(title: "")
            let item = NSMenuItem(
                title: "在终端中打开这里",
                action: #selector(openTerminalAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            
            if let img = NSImage(systemSymbolName: "terminal", accessibilityDescription: "在终端中打开这里") {
                img.isTemplate = true
                item.image = img
            }
            menu.addItem(item)
            return menu
        default:
            return nil
        }
    }
    
    // MARK: - Action Handling
    
    @objc func openTerminalAction(_ sender: Any?) {
        let folderURL = resolveTargetDirectory()
        let path = folderURL?.path ?? ""
        
        NSLog("[FinderTerminalExtension] Dispatching terminal open for path: \(path)")
        
        // Use custom URL scheme to hand off opening Terminal to the companion host app (FinderTerminal).
        // Sandboxed extensions cannot directly pass arbitrary filesystem URLs to external applications
        // without triggering macOS sandbox permission dialogs. Delegating to the host app avoids
        // any sandbox warnings and opens Terminal instantly and silently.
        var components = URLComponents()
        components.scheme = "finderterminal"
        components.host = "open"
        if !path.isEmpty {
            components.queryItems = [URLQueryItem(name: "path", value: path)]
        }
        
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func resolveTargetDirectory() -> URL? {
        let controller = FIFinderSyncController.default()
        
        // 1. Check if user right-clicked one or more selected items (folder or file)
        if let selected = controller.selectedItemURLs(), let first = selected.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir) {
                return isDir.boolValue ? first : first.deletingLastPathComponent()
            }
            return first.deletingLastPathComponent()
        }
        
        // 2. Check if user clicked empty whitespace in the folder
        if let targeted = controller.targetedURL() {
            return targeted
        }
        
        return nil
    }
}

@main
struct ExtensionMain {
    static func main() {
        _ = NSExtensionMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
}
