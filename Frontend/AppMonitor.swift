//
//  AppMonitor.swift
//  Frontend
//
//  Monitors active macOS application and sends updates to backend
//

import Foundation
import AppKit
import Combine

class AppMonitor: ObservableObject {
    // MARK: - Published PropertiesObservableObject
    @Published var currentApp: String = ""
    @Published var hasPermission: Bool = false

    // MARK: - Private Properties
    private var workspace = NSWorkspace.shared
    private var observer: NSObjectProtocol?
    private weak var webSocketManager: WebSocketManager?

    // MARK: - Initialization
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        checkPermissions()
    }

    // MARK: - Permission Check
    func checkPermissions() {
        // Check if we have accessibility permissions
        // This is required to detect the active application
        let trusted = AXIsProcessTrusted()

        DispatchQueue.main.async {
            self.hasPermission = trusted

            if trusted {
                print("✅ Accessibility permissions granted")
            } else {
                print("⚠️ Accessibility permissions required")
            }
        }
    }

    // MARK: - Start Monitoring
    func startMonitoring() {
        // Check permissions first
        checkPermissions()

        guard hasPermission else {
            print("❌ Cannot start monitoring - no accessibility permissions")
            return
        }

        // Listen for app activation notifications
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let appName = app.localizedName else {
                return
            }

            // Only send update if app changed
            if self.currentApp != appName {
                print("🔄 App switched: \(self.currentApp) → \(appName)")
                self.currentApp = appName
                self.webSocketManager?.sendAppUpdate(appName: appName)
            }
        }

        // Get the currently active app immediately
        if let activeApp = workspace.frontmostApplication?.localizedName {
            print("📱 Current app: \(activeApp)")
            currentApp = activeApp
            webSocketManager?.sendAppUpdate(appName: activeApp)
        }

        print("✅ App monitoring started")
    }

    // MARK: - Stop Monitoring
    func stopMonitoring() {
        if let observer = observer {
            workspace.notificationCenter.removeObserver(observer)
            self.observer = nil
        }
        print("🛑 App monitoring stopped")
    }

    // MARK: - Request Permissions
    func requestPermissions() {
        // First trigger the system prompt if not already trusted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        DispatchQueue.main.async {
            self.hasPermission = trusted
        }

        if !trusted {
            // Also open System Settings as backup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Cleanup
    deinit {
        stopMonitoring()
    }
}
