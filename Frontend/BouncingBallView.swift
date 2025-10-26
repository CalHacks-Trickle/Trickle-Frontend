//
//  BouncingBallView.swift
//  Frontend
//
//  Simple bouncing ball that grows with productivity
//

import SwiftUI

struct BouncingBallView: View {
    let netProductivity: TimeInterval  // Focus time - Distraction time (in seconds)

    @State private var ballPosition: CGFloat = 0.0  // Absolute position in pixels from left edge
    @State private var ballSize: CGFloat = 20.0  // Diameter in pixels
    @State private var isMovingRight: Bool = true
    @State private var lastUpdateTime: Date = Date()

    // Constants
    let trackWidth: CGFloat = 600.0
    let trackHeight: CGFloat = 100.0
    let minBallSize: CGFloat = 20.0
    let maxBallSize: CGFloat = 200.0

    // Speed: 1 pixel per 5 seconds of focus time
    // That means: 600 pixels / (5 seconds per pixel) = 3000 seconds = 50 minutes per full traversal
    let pixelsPerSecond: CGFloat = 0.2  // 1 pixel / 5 seconds

    var body: some View {
        VStack(spacing: 20) {
            // Track
            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: trackWidth, height: trackHeight)

                // Track border
                RoundedRectangle(cornerRadius: 50)
                    .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    .frame(width: trackWidth, height: trackHeight)

                // Ball
                Circle()
                    .fill(
                        RadialGradient(
                            colors: ballColor,
                            center: .center,
                            startRadius: 0,
                            endRadius: ballSize / 2
                        )
                    )
                    .frame(width: ballSize, height: ballSize)
                    .shadow(color: ballGlowColor.opacity(0.6), radius: 20)
                    .offset(x: ballXPosition, y: 0)
            }
            .frame(width: trackWidth, height: trackHeight)

            // Stats
            VStack(spacing: 5) {
                Text("Productivity: \(formatTime(Int(netProductivity)))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text("Ball Size: \(Int(ballSize))px • Bounces: \(bounceCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .onChange(of: netProductivity) { oldValue, newValue in
            updateBall(netTime: newValue)
        }
        .onAppear {
            print("⚽ BouncingBallView appeared!")
            updateBall(netTime: netProductivity)
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Computed Properties

    private var ballXPosition: CGFloat {
        // ballPosition is already in pixels (0 to trackWidth)
        // Center the ball horizontally, accounting for ball size
        return ballPosition - (trackWidth / 2) + (ballSize / 2)
    }

    private var bounceCount: Int {
        // How many times the ball has bounced (each bounce = one full traversal)
        let totalPixelsTraveled = netProductivity * pixelsPerSecond
        return Int(totalPixelsTraveled / trackWidth)
    }

    private var ballColor: [Color] {
        if netProductivity > 0 {
            return [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF8C00")]
        } else {
            return [Color.gray, Color(hex: "5D6D7E")]
        }
    }

    private var ballGlowColor: Color {
        netProductivity > 0 ? Color.orange : Color.gray
    }

    // MARK: - Update Logic

    private func updateBall(netTime: TimeInterval) {
        let totalPixelsTraveled = netTime * pixelsPerSecond

        // Calculate how many full bounces completed
        let bounces = Int(totalPixelsTraveled / trackWidth)

        // Calculate position within current traversal (0 to trackWidth)
        let positionInTraversal = totalPixelsTraveled.truncatingRemainder(dividingBy: trackWidth)

        // Determine direction (alternates each bounce)
        let movingRight = bounces % 2 == 0

        // Calculate actual pixel position
        let newPosition = movingRight ? positionInTraversal : (trackWidth - positionInTraversal)

        // Grow ball size with each bounce: starts at 20px, grows by 3px per bounce
        let newSize = min(maxBallSize, minBallSize + CGFloat(bounces) * 3.0)

        // Update state
        ballPosition = newPosition
        isMovingRight = movingRight

        // Animate size changes
        if abs(ballSize - newSize) > 0.1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                ballSize = newSize
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        print("⚽ Starting ball animation timer at 60 FPS")
        // Animate at 60 FPS for smooth motion
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [self] _ in
            updateBall(netTime: self.netProductivity)
        }
    }

    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    // MARK: - Helper

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.blue.opacity(0.3)
        BouncingBallView(netProductivity: 150)  // 2.5 minutes = 5 bounces
    }
}
