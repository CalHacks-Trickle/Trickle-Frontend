//
//  AppMonitor.swift
//  Frontend
//
//  Monitors active macOS application and sends updates to backend
//

import Foundation
import AppKit
import Combine

// MARK: - App Usage Entry
struct AppUsageEntry: Identifiable {
    let id = UUID()
    let appName: String
    var totalTime: TimeInterval = 0  // in seconds
    var lastStartTime: Date?
}

class AppMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published var currentApp: String = ""
    @Published var hasPermission: Bool = false
    @Published var trackedApps: [AppUsageEntry] = []  // Frontend-tracked apps

    // MARK: - Private Properties
    private var workspace = NSWorkspace.shared
    private var observer: NSObjectProtocol?
    private weak var webSocketManager: WebSocketManager?
    private var currentAppStartTime: Date?

    // MARK: - Initialization
    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        checkPermissions()
    }

    // MARK: - Permission Check
    func checkPermissions() {
        // NSWorkspace.didActivateApplicationNotification works without accessibility permissions
        // We only check this for UI display purposes
        let trusted = AXIsProcessTrusted()

        DispatchQueue.main.async {
            // Always set to true since NSWorkspace works without accessibility API
            self.hasPermission = true

            if trusted {
                print("✅ Accessibility API available (bonus features enabled)")
            } else {
                print("ℹ️ Running without Accessibility API (basic monitoring works fine)")
            }
        }
    }

    // MARK: - Start Monitoring
    func startMonitoring() {
        print("🚀 startMonitoring() called")

        // NSWorkspace notifications don't actually require accessibility permissions
        // Set hasPermission to true so UI shows the garden view
        // Only actual Accessibility API calls (like getting window titles) need permissions
        print("✅ Starting app monitoring with NSWorkspace notifications...")

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

                // Track time for previous app
                self.recordAppTime()

                // Switch to new app
                self.currentApp = appName
                self.currentAppStartTime = Date()

                // Send to backend
                self.webSocketManager?.sendAppUpdate(appName: appName)
            }
        }

        // Get the currently active app immediately
        if let activeApp = workspace.frontmostApplication?.localizedName {
            print("📱 Current app on startup: \(activeApp)")
            currentApp = activeApp
            currentAppStartTime = Date()
            webSocketManager?.sendAppUpdate(appName: activeApp)
        } else {
            print("⚠️ Could not get current active app")
        }

        print("✅ App monitoring started successfully")
    }

    // MARK: - Record App Time
    private func recordAppTime() {
        guard !currentApp.isEmpty,
              let startTime = currentAppStartTime else {
            return
        }

        let timeSpent = Date().timeIntervalSince(startTime)

        DispatchQueue.main.async {
            // Find existing entry or create new one
            if let index = self.trackedApps.firstIndex(where: { $0.appName == self.currentApp }) {
                self.trackedApps[index].totalTime += timeSpent
            } else {
                var newEntry = AppUsageEntry(appName: self.currentApp)
                newEntry.totalTime = timeSpent
                self.trackedApps.append(newEntry)
            }

            // Sort by total time descending
            self.trackedApps.sort { $0.totalTime > $1.totalTime }

            print("⏱️ Recorded \(Int(timeSpent))s for \(self.currentApp). Total: \(Int(self.trackedApps.first(where: { $0.appName == self.currentApp })?.totalTime ?? 0))s")
        }
    }

    // MARK: - Stop Monitoring
    func stopMonitoring() {
        // Record time for current app before stopping
        recordAppTime()

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
