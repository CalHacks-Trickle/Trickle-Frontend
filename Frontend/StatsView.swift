//
//  StatsView.swift
//  Frontend
//
//  Display today's summary and app usage statistics
//

import SwiftUI

struct StatsView: View {
    let todaySummary: TodaySummary
    let appUsage: AppUsage
    @State private var showAppDetails = false

    var body: some View {
        VStack(spacing: 15) {
            // Summary Cards
            HStack(spacing: 15) {
                StatCard(
                    title: "Focus Time",
                    value: formatTime(todaySummary.totalFocusTime),
                    icon: "🎯",
                    color: .green
                )

                StatCard(
                    title: "Distraction",
                    value: formatTime(todaySummary.totalDistractionTime),
                    icon: "📱",
                    color: .orange
                )

                StatCard(
                    title: "Best Streak",
                    value: formatTime(todaySummary.longestFocusStreak),
                    icon: "🔥",
                    color: .blue
                )
            }

            // App Details (Collapsible)
            DisclosureGroup(isExpanded: $showAppDetails) {
                VStack(spacing: 12) {
                    // Focus Apps
                    if !appUsage.focus.apps.isEmpty {
                        AppCategoryView(
                            title: "Focus Apps",
                            apps: appUsage.focus.apps,
                            totalTime: appUsage.focus.totalTime,
                            color: .green
                        )
                    }

                    // Distraction Apps
                    if !appUsage.distraction.apps.isEmpty {
                        AppCategoryView(
                            title: "Distraction Apps",
                            apps: appUsage.distraction.apps,
                            totalTime: appUsage.distraction.totalTime,
                            color: .orange
                        )
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack {
                    Text("App Details")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: showAppDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(20)
    }

    // MARK: - Helper Functions
    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 30))

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.6))
        .cornerRadius(15)
    }
}

// MARK: - App Category View
struct AppCategoryView: View {
    let title: String
    let apps: [AppDetail]
    let totalTime: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Text(formatTime(totalTime))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.bottom, 4)

            // App List
            ForEach(apps.prefix(5), id: \.name) { app in
                HStack {
                    // App Name
                    Text(app.name)
                        .font(.caption)
                        .foregroundColor(.white)

                    Spacer()

                    // Time
                    Text(formatTime(app.time))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))

                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(color)
                                .frame(width: geo.size.width * CGFloat(app.time) / CGFloat(totalTime), height: 4)
                                .cornerRadius(2)
                        }
                    }
                    .frame(width: 60, height: 4)
                }
            }

            // Show "and X more" if there are more apps
            if apps.count > 5 {
                Text("... and \(apps.count - 5) more")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            }
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(10)
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        StatsView(
            todaySummary: TodaySummary(
                totalFocusTime: 7200,
                totalDistractionTime: 900,
                longestFocusStreak: 3600,
                lastUpdated: "2023-10-27T10:00:00Z"
            ),
            appUsage: AppUsage(
                focus: AppCategory(
                    totalTime: 7200,
                    apps: [
                        AppDetail(name: "Visual Studio Code", time: 5400),
                        AppDetail(name: "iTerm2", time: 1200),
                        AppDetail(name: "Figma", time: 600)
                    ]
                ),
                distraction: AppCategory(
                    totalTime: 900,
                    apps: [
                        AppDetail(name: "Instagram", time: 600),
                        AppDetail(name: "X", time: 300)
                    ]
                )
            )
        )
    }
}
