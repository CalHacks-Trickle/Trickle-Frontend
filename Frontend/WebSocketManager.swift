//
//  WebSocketManager.swift
//  Frontend
//
//  Socket.IO connection manager for real-time garden state updates
//

import Foundation
import Combine
import SocketIO

class WebSocketManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentState: FocusState = .focusing
    @Published var gardenData: GardenStateResponse?
    @Published var isConnected: Bool = false
    @Published var connectionError: String?

    // MARK: - Private Properties
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let token: String
    private let serverURL = "http://20.172.68.176:3000"
    private var updateTimer: Timer?

    // MARK: - Initialization
    init(token: String) {
        self.token = token
        print("🔑 Token being sent: \(token.prefix(30))...")
        connect()
    }

    // MARK: - Connection Management
    func connect() {
        // Create Socket.IO manager with configuration
        // Send token in BOTH extraHeaders AND auth payload to match backend
        manager = SocketManager(
            socketURL: URL(string: serverURL)!,
            config: [
                .log(true),  // Enable logging for debugging
                .compress,
                .forceWebsockets(true),  // Use WebSocket transport
                .secure(false),  // http not https
                .reconnects(true),  // Auto-reconnect
                .reconnectAttempts(-1),  // Infinite reconnect attempts
                .reconnectWait(5),  // Wait 5 seconds between reconnects
                .connectParams(["token": self.token]),  // Send token with "Bearer" prefix
            ]
        )

        // Get default socket
        socket = manager?.defaultSocket

        // Setup event listeners
        setupEventListeners()

        // Connect with auth payload - this matches: {auth: {token: JWT_TOKEN}}
        socket?.connect(withPayload: ["auth": ["token": token]])

        print("🔄 Socket.IO connecting to \(serverURL)")
        print("🔑 Token being sent: \(token.prefix(30))...")
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        isConnected = false
        print("🔌 Socket.IO disconnected")
    }

    // MARK: - Event Listeners
    private func setupEventListeners() {
        // Connection successful
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ Socket.IO connected successfully!")
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionError = nil
                self?.startPeriodicUpdates()
            }
        }

        // Connection error
        socket?.on(clientEvent: .error) { [weak self] data, ack in
            print("❌ Socket.IO error: \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionError = "Connection error: \(data)"
            }
        }

        // Disconnect
        socket?.on(clientEvent: .disconnect) { [weak self] data, ack in
            print("🔌 Socket.IO disconnected: \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.stopPeriodicUpdates()
            }
        }

        // Connection error (authentication, etc.)
        socket?.on("connect_error") { [weak self] data, ack in
            print("❌ Connection error: \(data)")
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionError = "Authentication failed or connection error"
            }
        }

        // Listen for status updates from backend
        socket?.on("status-updated") { [weak self] data, ack in
            print("📩 Received status-updated event")
            self?.handleGardenUpdate(data)
        }

        // Listen for any other messages (for debugging)
        socket?.onAny { event in
            print("📨 Socket.IO event: \(event.event), data: \(event.items ?? [])")
        }
    }

    // MARK: - Send App Update
    func sendAppUpdate(appName: String) {
        guard isConnected else {
            print("⚠️ Cannot send app update - not connected")
            return
        }

        // Send update-app event with appName
        socket?.emit("update-app", ["appName": appName])
        print("📤 Sent app update: \(appName)")
    }

    // MARK: - Handle Garden Update
    private func handleGardenUpdate(_ data: [Any]) {
        // Socket.IO sends data as an array
        // The first element is typically the payload
        guard let firstItem = data.first else {
            print("⚠️ No data in garden-update event")
            return
        }

        // Try to convert to JSON data
        var jsonData: Data?

        if let dict = firstItem as? [String: Any] {
            // If it's a dictionary, convert to JSON data
            do {
                jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            } catch {
                print("❌ Failed to serialize dictionary to JSON: \(error)")
                return
            }
        } else if let string = firstItem as? String {
            // If it's a string, convert to data
            jsonData = string.data(using: .utf8)
        } else {
            print("⚠️ Unexpected data type: \(type(of: firstItem))")
            return
        }

        guard let data = jsonData else {
            print("⚠️ Could not convert data to JSON")
            return
        }

        // Parse the JSON
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(GardenStateResponse.self, from: data)

            DispatchQueue.main.async {
                self.gardenData = response
                self.currentState = FocusState(rawValue: response.currentState) ?? .focusing

                let netProductivity = response.todaySummary.totalFocusTime - response.todaySummary.totalDistractionTime

                print("⚽ BOUNCING BALL - Status updated:")
                print("   - State: \(response.currentState)")
                print("   - Focus Time: \(response.todaySummary.totalFocusTime)s")
                print("   - Distraction Time: \(response.todaySummary.totalDistractionTime)s")
                print("   - Net Productivity: \(netProductivity)s \(netProductivity > 0 ? "📈" : "📉")")
            }
        } catch {
            print("❌ JSON decode error: \(error)")
            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
        }
    }

    // MARK: - Periodic Updates
    private func startPeriodicUpdates() {
        // Stop existing timer if any
        stopPeriodicUpdates()

        // Request update every 5 seconds while viewing the app
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.requestStatusUpdate()
        }

        // Request initial update immediately
        requestStatusUpdate()

        print("⏰ Started periodic status updates (every 5s)")
    }

    private func stopPeriodicUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("⏰ Stopped periodic status updates")
    }

    private func requestStatusUpdate() {
        guard isConnected else {
            return
        }

        // Request fresh status from backend
        socket?.emit("get-status")
        print("📤 Requested status update")
    }

    // MARK: - Cleanup
    deinit {
        stopPeriodicUpdates()
        disconnect()
    }
}
