//
//  GardenView.swift
//  Frontend
//
//  Main garden view with dynamic backgrounds
//

import SwiftUI

struct GardenView: View {
    @ObservedObject var webSocketManager: WebSocketManager
    @StateObject private var appMonitor: AppMonitor
    @EnvironmentObject var authViewModel: AuthViewModel

    init(webSocketManager: WebSocketManager) {
        self.webSocketManager = webSocketManager
        _appMonitor = StateObject(wrappedValue: AppMonitor(webSocketManager: webSocketManager))
    }

    var body: some View {
        ZStack {
            // Check if permissions are granted
            if !appMonitor.hasPermission {
                // Show permissions request screen
                PermissionsView(appMonitor: appMonitor)
            } else {
                // Show normal garden view
                gardenContent
            }
        }
        .onAppear {
            print("🌳 GardenView appeared - starting app monitoring")
            // Start monitoring when view appears
            appMonitor.startMonitoring()
        }
        .onDisappear {
            print("👋 GardenView disappeared - stopping app monitoring")
            // Stop monitoring when view disappears
            appMonitor.stopMonitoring()
        }
    }

    // MARK: - Garden Content
    private var gardenContent: some View {
        ZStack {
            // LAYER 1: Dynamic Background with smooth transition
            if webSocketManager.currentState == .focusing {
                FertileBackgroundView()
                    .transition(.opacity)
                    .zIndex(0)
            } else {
                DesertBackgroundView()
                    .transition(.opacity)
                    .zIndex(0)
            }

            // LAYER 2: Content Overlay with Scroll
            ScrollView {
                VStack(spacing: 20) {
                    // Header: Connection Status
                    HeaderView(
                        isConnected: webSocketManager.isConnected,
                        currentState: webSocketManager.currentState
                    )

                    // Center: Bouncing Ball Visualization
                    if let data = webSocketManager.gardenData {
                        let netProductivity = TimeInterval(data.sessionSummary.totalFocusTime - data.sessionSummary.totalDistractionTime)

                        BouncingBallView(netProductivity: netProductivity)
                            .transition(.scale.combined(with: .opacity))
                            .padding(.vertical, 40)
                            .onChange(of: netProductivity) { oldValue, newValue in
                                print("📊 GardenView: Net productivity changed from \(Int(oldValue))s to \(Int(newValue))s")
                            }
                    } else {
                        // Loading state
                        ProgressView("Loading your garden...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .foregroundColor(.white)
                            .padding(.vertical, 40)
                    }

                    // Two-Section Stats Layout
                    VStack(spacing: 15) {
                        // Section 1: Frontend-Only Tracking
                        FrontendStatsView(
                            trackedApps: appMonitor.trackedApps,
                            currentApp: appMonitor.currentApp
                        )

                        // Section 2: Backend Response
                        if let data = webSocketManager.gardenData {
                            StatsView(
                                todaySummary: data.todaySummary,
                                appUsage: data.appUsage
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    // Logout Button
                    Button(action: {
                        webSocketManager.disconnect()
                        authViewModel.logout()
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .animation(.easeInOut(duration: 1.5), value: webSocketManager.currentState)
    }
}

// MARK: - Header View
struct HeaderView: View {
    let isConnected: Bool
    let currentState: FocusState

    var body: some View {
        HStack {
            // Connection indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)

                Text(isConnected ? "Connected" : "Disconnected")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.4))
            .cornerRadius(15)

            Spacer()

            // Current state indicator
            HStack(spacing: 8) {
                Text(currentState == .focusing ? "🌞" : "🔥")
                    .font(.title3)

                Text(currentState == .focusing ? "Focusing" : "Distracted")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                (currentState == .focusing ? Color.green : Color.orange)
                    .opacity(0.7)
            )
            .cornerRadius(20)
        }
    }
}

#Preview {
    GardenView(
        webSocketManager: WebSocketManager(token: "preview-token")
    )
    .environmentObject(AuthViewModel())
}
