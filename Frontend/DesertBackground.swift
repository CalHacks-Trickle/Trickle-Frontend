import SwiftUI

struct DesertBackgroundView: View {
    var body: some View {
        // Wrap the ZStack in a GeometryReader to get the available size
        GeometryReader { geo in
            ZStack {
                // Gradient for a dry, dusty sky
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.4, blue: 0.2, opacity: 0.9), // Darker orange/brown
                        Color(red: 0.9, green: 0.7, blue: 0.5, opacity: 0.9)  // Lighter, dusty orange
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Distant Dunes (Subtle hills)
                Path { path in
                    // Use geo.size instead of UIScreen
                    let width = geo.size.width
                    let height = geo.size.height

                    // First dune layer
                    path.move(to: CGPoint(x: 0, y: height * 0.7))
                    path.addCurve(to: CGPoint(x: width, y: height * 0.65),
                                  control1: CGPoint(x: width * 0.3, y: height * 0.8),
                                  control2: CGPoint(x: width * 0.7, y: height * 0.5))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .fill(Color(red: 0.8, green: 0.6, blue: 0.4).opacity(0.7)) // Sandy color
                .offset(y: 50) // Adjust position

                // Closer, slightly darker dune layer
                Path { path in
                    // Use geo.size instead of UIScreen
                    let width = geo.size.width
                    let height = geo.size.height

                    path.move(to: CGPoint(x: 0, y: height * 0.75))
                    path.addCurve(to: CGPoint(x: width, y: height * 0.7),
                                  control1: CGPoint(x: width * 0.2, y: height * 0.85),
                                  control2: CGPoint(x: width * 0.8, y: height * 0.6))
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                }
                .fill(Color(red: 0.7, green: 0.5, blue: 0.3).opacity(0.8)) // Darker sand
                .offset(y: 80) // Adjust position

                // Ground/Foreground (more reddish-brown)
                Rectangle()
                    .fill(Color(red: 0.5, green: 0.3, blue: 0.1, opacity: 0.9))
                    // Use geo.size instead of UIScreen
                    .frame(height: geo.size.height * 0.3)
                    .offset(y: geo.size.height * 0.35) // Position at the bottom
                
                // Subtle dust/haze effect
                Rectangle()
                    .fill(Color.white.opacity(0.1)) // A light, dusty haze
                    .rotationEffect(.degrees(10))
                    .blur(radius: 20)
                    .offset(x: -50, y: 100)
                
                // Cracks or dry texture (optional, could be an image too)
                // For a quick hackathon, simple lines or circles might suggest it
                ForEach(0..<10) { _ in
                    Circle()
                        .frame(width: CGFloat.random(in: 5...20), height: CGFloat.random(in: 5...20))
                        .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.0).opacity(0.3))
                        // Use geo.size instead of UIScreen
                        .position(x: CGFloat.random(in: 0...geo.size.width),
                                  y: CGFloat.random(in: geo.size.height * 0.75...geo.size.height - 20))
                }

            }
            .clipped() // Ensure nothing draws outside the bounds
        }
    }
}

#Preview {
    DesertBackgroundView()
}

