import Foundation
import ServiceManagement

class LaunchAtLogin {
    static let shared = LaunchAtLogin()
    
    private let launchAgentIdentifier = "com.vibe.FinderTerminal"
    
    private var launchAgentFile: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
            .appendingPathComponent("\(launchAgentIdentifier).plist")
    }
    
    var isEnabled: Bool {
        get {
            // First check SMAppService if available (macOS 13+)
            if #available(macOS 13.0, *) {
                let status = SMAppService.mainApp.status
                if status == .enabled {
                    return true
                }
            }
            // Fallback: check LaunchAgent file
            return FileManager.default.fileExists(atPath: launchAgentFile.path)
        }
        set {
            set(enabled: newValue)
        }
    }
    
    func set(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                // If SMAppService succeeds, clean up any old LaunchAgent plist file
                if !enabled && FileManager.default.fileExists(atPath: launchAgentFile.path) {
                    try? FileManager.default.removeItem(at: launchAgentFile)
                }
                return
            } catch {
                NSLog("[FinderTerminal] SMAppService failed, falling back to LaunchAgent: \(error)")
            }
        }
        
        // LaunchAgent fallback (works universally on all macOS versions)
        let launchAgentsDir = launchAgentFile.deletingLastPathComponent()
        if enabled {
            try? FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            let appPath = Bundle.main.bundlePath
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(launchAgentIdentifier)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/usr/bin/open</string>
                    <string>\(appPath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>ProcessType</key>
                <string>Interactive</string>
            </dict>
            </plist>
            """
            try? plistContent.write(to: launchAgentFile, atomically: true, encoding: .utf8)
        } else {
            if FileManager.default.fileExists(atPath: launchAgentFile.path) {
                try? FileManager.default.removeItem(at: launchAgentFile)
            }
        }
    }
}
