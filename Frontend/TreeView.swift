//
//  TreeView.swift
//  Frontend
//
//  Tree visualization based on level and health
//

import SwiftUI

struct TreeView: View {
    let tree: Tree

    var body: some View {
        VStack(spacing: 15) {
            // Tree Visual
            Text(treeEmoji)
                .font(.system(size: treeSize))
                .shadow(color: treeShadowColor, radius: 10)
                .scaleEffect(healthScale)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: tree.level ?? 1)
                .animation(.easeInOut(duration: 0.5), value: tree.health ?? 100.0)

            // Health Bar
            VStack(spacing: 5) {
                HStack {
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(Int(tree.health ?? 100.0))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(healthColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 12)
                            .cornerRadius(6)

                        // Health fill
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [healthColor, healthColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat((tree.health ?? 100.0) / 100.0), height: 12)
                            .cornerRadius(6)
                            .animation(.easeInOut(duration: 0.8), value: tree.health ?? 100.0)
                    }
                }
                .frame(height: 12)
            }
            .padding(.horizontal)

            // Level Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Level \(tree.level ?? 1)")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("Next: Level \((tree.level ?? 1) + 1)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 10)
                            .cornerRadius(5)

                        // Progress fill
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat((tree.progressToNextLevel ?? 0.0) / 100.0), height: 10)
                            .cornerRadius(5)
                            .animation(.easeInOut(duration: 0.8), value: tree.progressToNextLevel ?? 0.0)
                    }
                }
                .frame(height: 10)

                Text("\(Int(tree.progressToNextLevel ?? 0.0))% to next level")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(15)
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(20)
    }

    // MARK: - Computed Properties

    private var treeEmoji: String {
        switch tree.level ?? 1 {
        case 0:
            return "🌱" // Seed
        case 1:
            return "🌿" // Sprout
        case 2...3:
            return "🌳" // Young tree
        case 4...6:
            return "🌲" // Mature tree
        case 7...9:
            return "🎄" // Majestic tree
        case 10:
            return "🌴" // Ultimate tree
        default:
            return "🌱"
        }
    }

    private var treeSize: CGFloat {
        // Base size + growth per level
        let baseSize: CGFloat = 80
        let growthPerLevel: CGFloat = 15
        return baseSize + (CGFloat(tree.level ?? 1) * growthPerLevel)
    }

    private var healthScale: CGFloat {
        // Scale slightly based on health (0.8 - 1.0)
        return 0.8 + ((tree.health ?? 100.0) / 100.0 * 0.2)
    }

    private var healthColor: Color {
        let health = tree.health ?? 100.0
        if health >= 80 {
            return .green
        } else if health >= 50 {
            return .yellow
        } else if health >= 25 {
            return .orange
        } else {
            return .red
        }
    }

    private var treeShadowColor: Color {
        let health = tree.health ?? 100.0
        if health >= 80 {
            return .green.opacity(0.5)
        } else if health >= 50 {
            return .yellow.opacity(0.5)
        } else {
            return .red.opacity(0.5)
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        TreeView(tree: Tree(level: 5, health: 85.5, progressToNextLevel: 67.3))
    }
}
