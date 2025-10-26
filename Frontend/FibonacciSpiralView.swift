//
//  FibonacciSpiralView.swift
//  Frontend
//
//  Continuously growing Fibonacci spiral based on productivity
//

import SwiftUI

struct FibonacciSpiralView: View {
    let netProductivity: TimeInterval  // Focus time - Distraction time (in seconds)

    // Animation state
    @State private var segments: Int = 4  // Start tiny - just 4 segments (almost a dot)

    var body: some View {
        ZStack {
            // One continuous spiral that grows and zooms out
            // Scale is baked into the path, not applied as transform (prevents pivoting)
            ExpandingFibonacciSpiral(segmentCount: segments)
                .stroke(
                    AngularGradient(
                        colors: spiralColor,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 500, height: 500)
                .shadow(color: spiralGlowColor.opacity(0.6), radius: 20)
                .animation(.linear(duration: 2.0), value: segments)

            // Center dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: centerDotColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: 4
                    )
                )
                .frame(width: 8, height: 8)
                .shadow(color: spiralGlowColor.opacity(0.8), radius: 8)
        }
        .frame(width: 500, height: 500)
        .background(Color.red.opacity(0.1))  // DEBUG: See if view is rendering
        .onChange(of: netProductivity) { oldValue, newValue in
            print("📈 NetProductivity changed: \(Int(oldValue))s → \(Int(newValue))s")
            updateProgress(netTime: newValue)
        }
        .onAppear {
            print("👁️ FibonacciSpiralView appeared with netProductivity: \(Int(netProductivity))s")
            updateProgress(netTime: netProductivity)
        }
    }

    // MARK: - Update Progress
    private func updateProgress(netTime: TimeInterval) {
        let minutes = max(0, netTime / 60.0)  // Never negative!

        // UNIFIED GROWTH ALGORITHM
        // EXTREMELY slow growth - like watching an ant build over hours

        // Linear growth: 1 segment per 10 minutes
        // This is slow enough to appreciate every single segment addition
        let targetSegments = max(4, min(30, Int(4.0 + minutes / 10.0)))

        // Calculate the actual pixel size the spiral would be at this segment count
        // Generate fibonacci to see how big the last number is
        var fib = generateFibonacci(count: targetSegments)
        let largestFib = fib.last ?? 1

        // Calculate scale to keep spiral fitting nicely in 500px frame
        // Target: largest arc should be about 400px (leaving 50px margin on each side)
        let desiredLargestArcSize: CGFloat = 400.0
        let targetScale = desiredLargestArcSize / largestFib

        print("🌀 Fibonacci Spiral Growth:")
        print("   - Productivity: \(String(format: "%.1f", minutes)) min")
        print("   - Target Segments: \(targetSegments) (current: \(segments))")
        print("   - Largest Fib: \(Int(largestFib))")
        print("   - Pixel Scale: \(String(format: "%.4f", targetScale))")

        // Grow gradually - add 1 segment at a time with smooth animation
        if targetSegments > segments {
            withAnimation(.linear(duration: 1.0)) {
                segments = min(segments + 1, targetSegments)
            }

            // Schedule next growth step if needed
            if segments < targetSegments {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateProgress(netTime: netTime)
                }
            }
        }
    }

    // Helper to generate fibonacci numbers
    private func generateFibonacci(count: Int) -> [CGFloat] {
        var fib: [CGFloat] = [1, 1]
        while fib.count < count {
            let next = fib[fib.count - 1] + fib[fib.count - 2]
            fib.append(next)
        }
        return Array(fib.prefix(count))
    }

    // MARK: - Colors
    private var spiralColor: [Color] {
        if netProductivity > 0 {
            return [Color(hex: "FFD700"), Color(hex: "FFA500"), Color(hex: "FF8C00"), Color(hex: "FF6B35")]
        } else if netProductivity < -300 {
            return [Color(hex: "FF6B6B"), Color(hex: "C44569"), Color(hex: "8B0000")]
        } else {
            return [Color(hex: "95A5A6"), Color(hex: "7F8C8D"), Color(hex: "5D6D7E")]
        }
    }

    private var centerDotColors: [Color] {
        netProductivity > 0 ? [Color.yellow, Color.orange] : [Color.gray, Color(hex: "5D6D7E")]
    }

    private var spiralGlowColor: Color {
        netProductivity > 0 ? Color.yellow : Color.gray
    }
}

// MARK: - Expanding Fibonacci Spiral Shape
struct ExpandingFibonacciSpiral: Shape {
    let segmentCount: Int  // How many segments to draw

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)

        // Generate Fibonacci numbers dynamically based on segment count
        // Cap at 30 segments to avoid integer overflow (30th Fib ≈ 832,040)
        let safeSegmentCount = min(segmentCount, 30)

        var fibonacci: [CGFloat] = [1, 1]
        while fibonacci.count < safeSegmentCount {
            let prev = fibonacci[fibonacci.count - 1]
            let prevPrev = fibonacci[fibonacci.count - 2]
            let next = prev + prevPrev
            fibonacci.append(next)
        }

        // Use only the segments we need
        let segmentsToUse = Array(fibonacci.prefix(safeSegmentCount))

        print("🎨 Drawing spiral: \(safeSegmentCount) segments, fibonacci: \(segmentsToUse.prefix(5))...")
        print("   Rect: \(rect.width)x\(rect.height)")

        // Fixed scale - each unit is a consistent size
        // Scale reduces as more segments are added to keep total size reasonable
        // Target: keep spiral under 1000px even with 30 segments
        let baseScale: CGFloat = 600.0 / CGFloat(segmentsToUse.last ?? 1)
        let scale: CGFloat = max(0.5, baseScale)  // At least 0.5px per unit

        print("   Last Fibonacci: \(segmentsToUse.last ?? 0), Scale: \(String(format: "%.3f", scale))")

        // Draw continuous spiral
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var direction = 0

        for (index, fib) in segmentsToUse.enumerated() {
            let size = CGFloat(fib) * scale

            let arcCenter: CGPoint
            let startAngle: Angle
            let endAngle: Angle

            switch direction % 4 {
            case 0: // Right
                arcCenter = CGPoint(x: center.x + currentX + size, y: center.y + currentY + size)
                startAngle = .degrees(180)
                endAngle = .degrees(270)
                currentY += size

            case 1: // Up
                arcCenter = CGPoint(x: center.x + currentX + size, y: center.y + currentY - size)
                startAngle = .degrees(90)
                endAngle = .degrees(180)
                currentX += size

            case 2: // Left
                arcCenter = CGPoint(x: center.x + currentX - size, y: center.y + currentY - size)
                startAngle = .degrees(0)
                endAngle = .degrees(90)
                currentY -= size

            case 3: // Down
                arcCenter = CGPoint(x: center.x + currentX - size, y: center.y + currentY + size)
                startAngle = .degrees(270)
                endAngle = .degrees(360)
                currentX -= size

            default:
                continue
            }

            if index == 0 {
                path.move(to: CGPoint(
                    x: arcCenter.x + size * CGFloat(cos(startAngle.radians)),
                    y: arcCenter.y + size * CGFloat(sin(startAngle.radians))
                ))
            }

            path.addArc(
                center: arcCenter,
                radius: size,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )

            direction += 1
        }

        return path
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3)

        // Preview with actual productivity data
        FibonacciSpiralView(netProductivity: 3926)
            .frame(height: 600)
    }
}
