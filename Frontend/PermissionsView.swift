//
//  PermissionsView.swift
//  Frontend
//
//  Permission request screen for Accessibility access
//

import SwiftUI
import AppKit

struct PermissionsView: View {
    @ObservedObject var appMonitor: AppMonitor
    @State private var isChecking = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "lock.shield")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            // Title
            Text("Accessibility Permission Required")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Description
            VStack(alignment: .leading, spacing: 15) {
                Text("To track your focus and help your garden grow, this app needs permission to:")
                    .font(.body)
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                    Text("Detect which application you're currently using")
                }
                .font(.body)

                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                    Text("Send this information to help determine your focus state")
                }
                .font(.body)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal, 40)

            // Instructions
            VStack(spacing: 10) {
                Text("How to grant permission:")
                    .font(.headline)

                Text("1. Click 'Open System Settings' below")
                    .font(.caption)
                Text("2. Find and enable 'Frontend' in the list")
                    .font(.caption)
                Text("3. Come back and click 'Check Again'")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Buttons
            VStack(spacing: 15) {
                Button(action: {
                    appMonitor.requestPermissions()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open System Settings")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                Button(action: {
                    isChecking = true
                    appMonitor.checkPermissions()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isChecking = false
                    }
                }) {
                    HStack {
                        if isChecking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check Again")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    PermissionsView(appMonitor: AppMonitor(webSocketManager: WebSocketManager(token: "preview-token")))
}
