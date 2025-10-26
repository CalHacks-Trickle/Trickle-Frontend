import SwiftUI

struct FertileBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Gradient for a bright, clear sky
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.cyan.opacity(0.8),    // Lighter blue for the top
                        Color.blue.opacity(0.6),    // Deeper blue
                        Color.green.opacity(0.4)    // Hint of green near the horizon
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Subtle sun or glow
                Circle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.3) // Top-left corner

                // Lush hills/ground (using Paths for organic shapes)
                Path { path in
                    let width = geo.size.width
                    let height = geo.size.height

                    // Main hill layer (darker green)
                    path.move(to: CGPoint(x: 0, y: height * 0.6))
                    path.addQuadCurve(to: CGPoint(x: width, y: height * 0.55),
                                      control: CGPoint(x: width * 0.5, y: height * 0.7))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .fill(Color.green.opacity(0.7))
                .offset(y: 50) // Adjust position

                // Foreground, more fertile soil (darker, richer green)
                Rectangle()
                    .fill(Color.green.opacity(0.9))
                    .frame(height: geo.size.height * 0.4)
                    .offset(y: geo.size.height * 0.3) // Position at the bottom

                // Optional: small grassy tufts or dots for detail
                ForEach(0..<20) { _ in
                    Circle()
                        .frame(width: CGFloat.random(in: 3...10), height: CGFloat.random(in: 3...10))
                        .foregroundColor(Color.green.opacity(CGFloat.random(in: 0.3...0.6)))
                        .position(x: CGFloat.random(in: 0...geo.size.width),
                                  y: CGFloat.random(in: geo.size.height * 0.7...geo.size.height - 30))
                }
            }
            .clipped()
        }
    }
}

#Preview {
    FertileBackgroundView()
}
