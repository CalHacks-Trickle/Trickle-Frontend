//
//  BouncingBallView.swift
//  Frontend
//
//  Simple bouncing ball that grows with productivity
//
//  ---
//  NOTE: The 'extension Color { ... }' block was removed from the end
//  of this file. It was causing an "Invalid redeclaration" error,
//  which means that extension already exists elsewhere in your project.
//  Removing the duplicate copy here fixes both compiler errors.
//  ---
//

import SwiftUI

struct BouncingBallView: View {
    let netProductivity: TimeInterval  // Initial Focus time - Distraction time (in seconds)

    // State for the animation
    // UPDATED: ballPosition is now the CENTER of the ball, from 0 to trackWidth.
    // Initialized to minBallSize / 2.
    @State private var ballPosition: CGFloat = 5.0  // Absolute position in pixels from left edge
    @State private var ballSize: CGFloat = 10.0  // Diameter in pixels
    @State private var isMovingRight: Bool = true
    @State private var lastUpdateTime: Date = Date()
    
    // This is the *live* value that the timer will increase
    @State private var animatedNetProductivity: TimeInterval = 0.0
    
    // The timer object
    @State private var animationTimer: Timer? = nil // Corrected from 'time?' to 'Timer?'

    // Constants
    let trackWidth: CGFloat = 600.0
    let trackHeight: CGFloat = 100.0
    // UPDATED: Made ball sizes smaller
    let minBallSize: CGFloat = 10.0
    let maxBallSize: CGFloat = 100.0

    // Speed: 1 pixel per 5 seconds of focus time (Original: 0.2)
    // 0.2 pixels per second
    // UPDATED: Increased speed to be visible
    let pixelsPerSecond: CGFloat = 20.0

    var body: some View {
        VStack(spacing: 20) {
            // Track
            // UPDATED: Changed alignment to .center for correct offset calculations
            ZStack(alignment: .center) {
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
            .clipped() // Prevents ball from drawing outside the track

            // Stats
            VStack(spacing: 5) {
                // Display the *live* animated time
                Text("Productivity: \(formatTime(Int(animatedNetProductivity)))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text("Ball Size: \(Int(ballSize))px • Bounces: \(bounceCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .onChange(of: netProductivity) { oldValue, newValue in
            // If the parent view sends a new time, re-sync our animation
            self.animatedNetProductivity = newValue
            // Need to update ballSize *before* updateBall to get correct effectiveWidth
            let bounces = Int((newValue * pixelsPerSecond) / (trackWidth - ballSize)) // Approx.
            self.ballSize = min(maxBallSize, minBallSize + CGFloat(bounces) * 3.0)
            updateBall(netTime: newValue)
        }
        .onAppear {
            print("⚽ BouncingBallView appeared!")
            // Set the starting time
            self.animatedNetProductivity = netProductivity
            
            // Set the ball's initial size and position
            // We must set ballSize *first* so updateBall() can calculate the correct track width
            let initialBounces = Int((netProductivity * pixelsPerSecond) / (trackWidth - minBallSize)) // Approx.
            self.ballSize = min(maxBallSize, minBallSize + CGFloat(initialBounces) * 3.0)
            updateBall(netTime: self.animatedNetProductivity)
            
            // Start the timer to make it move
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // MARK: - Computed Properties

    private var ballXPosition: CGFloat {
        // UPDATED: ballPosition is now the center (0 to 600)
        // We map it to the centered ZStack's coordinates (-300 to 300)
        return ballPosition - (trackWidth / 2)
    }

    private var bounceCount: Int {
        // How many times the ball has bounced (each bounce = one full traversal)
        // Use an approximation of effective width for the counter
        let effectiveWidth = trackWidth - ballSize
        guard effectiveWidth > 0 else { return 0 }
        let totalPixelsTraveled = animatedNetProductivity * pixelsPerSecond // Use live time
        return Int(totalPixelsTraveled / effectiveWidth)
    }

    private var ballColor: [Color] {
        if animatedNetProductivity > 0 { // Use live time
            // Assuming Color(hex:) is available from another file in the project
            return [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF8C00")]
        } else {
            return [Color.gray, Color(hex: "5D6D7E")]
        }
    }

    private var ballGlowColor: Color {
        animatedNetProductivity > 0 ? Color.orange : Color.gray // Use live time
    }

    // MARK: - Update Logic

    private func updateBall(netTime: TimeInterval) {
        // UPDATED: The ball's center can't travel the *full* width.
        // It can only travel (trackWidth - ballSize).
        let effectiveWidth = trackWidth - ballSize
        guard effectiveWidth > 0 else {
            // Ball is as big as the track, just center it
            ballPosition = trackWidth / 2
            return
        }
        
        let totalPixelsTraveled = netTime * pixelsPerSecond

        // Calculate how many full bounces completed
        let bounces = Int(totalPixelsTraveled / effectiveWidth)

        // Calculate position within current traversal (0 to effectiveWidth)
        let positionInTraversal = totalPixelsTraveled.truncatingRemainder(dividingBy: effectiveWidth)

        // Determine direction (alternates each bounce)
        let movingRight = bounces % 2 == 0

        // Calculate actual pixel position (from 0 to effectiveWidth)
        let newPosition = movingRight ? positionInTraversal : (effectiveWidth - positionInTraversal)
        
        // UPDATED: We set ballPosition to be the *center* of the ball.
        // This maps the (0...effectiveWidth) position to the
        // (ballSize/2 ... trackWidth - ballSize/2) center position.
        let newCenterPosition = newPosition + (ballSize / 2)

        // --- Update State ---
        
        // Wrap position change in a linear animation for smooth movement
        withAnimation(.linear(duration: 1.0/60.0)) {
            ballPosition = newCenterPosition
        }
        
        isMovingRight = movingRight

        // Grow ball size with each bounce: starts at 10px, grows by 3px per bounce
        let newSize = min(maxBallSize, minBallSize + CGFloat(bounces) * 3.0)

        // Animate size changes with a "pop"
        if abs(ballSize - newSize) > 0.1 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                ballSize = newSize
            }
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        print("⚽ Starting ball animation timer at 60 FPS")
        self.lastUpdateTime = Date() // Set start time for delta
        
        // Animate at 60 FPS for smooth motion
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            let now = Date()
            // Calculate time passed since last frame
            let timeDelta = now.timeIntervalSince(self.lastUpdateTime)
            
            // Increment our live productivity score by the time passed
            // Only increase if productivity is positive or starting from 0
            // If it's negative, it should stay put.
            if self.animatedNetProductivity >= 0 {
                self.animatedNetProductivity += timeDelta
            }
            
            // Update the ball's position based on the new live time
            updateBall(netTime: self.animatedNetProductivity)
            
            // Store this frame's time for the next loop
            self.lastUpdateTime = now
        }
    }

    private func stopAnimation() {
        print("⚽ Stopping ball animation timer")
        animationTimer?.invalidate()
        animationTimer = nil
    }

    // MARK: - Helper

    private func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        // A dark background to see the view
        // This will now correctly find the *single* init(hex:)
        Color(hex: "2C3E50").ignoresSafeArea()
        
        // Previewing with 0 seconds of *initial* net productivity to show min ball size
        // UPDATED: Changed initial productivity to 0 for a smaller starting ball
        BouncingBallView(netProductivity: 0)
    }
}
