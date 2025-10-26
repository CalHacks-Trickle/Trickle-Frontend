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

                // --- REMOVED ---
                // Removed the "Lush hills/ground" Path
                // Removed the "Foreground, more fertile soil" Rectangle
                // Removed the "Optional: small grassy tufts" ForEach loop
                // ---
            }
            .clipped()
        }
    }
}

#Preview {
    FertileBackgroundView()
}
