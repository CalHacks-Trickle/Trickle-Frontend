//
//  FrontendStatsView.swift
//  Frontend
//
//  Display frontend-only tracked app usage (independent of backend)
//

import SwiftUI

struct FrontendStatsView: View {
    let trackedApps: [AppUsageEntry]
    let currentApp: String
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 15) {
            // Header with label
            HStack {
                Text("📱 Frontend Detection")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Current app indicator
            if !currentApp.isEmpty {
                HStack {
                    Text("Active Now:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text(currentApp)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(8)
            }

            // App list (collapsible)
            if !trackedApps.isEmpty {
                DisclosureGroup(isExpanded: $showDetails) {
                    VStack(spacing: 8) {
                        ForEach(trackedApps.prefix(10)) { entry in
                            HStack {
                                Text(entry.appName)
                                    .font(.caption)
                                    .foregroundColor(.white)

                                Spacer()

                                Text(formatTime(Int(entry.totalTime)))
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.vertical, 4)
                        }

                        if trackedApps.count > 10 {
                            Text("... and \(trackedApps.count - 10) more")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .italic()
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    HStack {
                        Text("\(trackedApps.count) apps tracked")
                            .font(.subheadline)
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
            } else {
                Text("Waiting for app activity...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .padding()
            }
        }
        .padding()
        .background(Color.purple.opacity(0.3))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.purple.opacity(0.6), lineWidth: 2)
        )
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        FrontendStatsView(
            trackedApps: [
                AppUsageEntry(appName: "Xcode", totalTime: 120),
                AppUsageEntry(appName: "Cursor", totalTime: 85),
                AppUsageEntry(appName: "Frontend", totalTime: 45)
            ],
            currentApp: "Xcode"
        )
        .padding()
    }
}
