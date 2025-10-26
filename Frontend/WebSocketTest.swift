//
//  WebSocketTest.swift
//  Frontend
//
//  Simple test to debug Socket.IO authentication
//

import Foundation
import SocketIO

class WebSocketTest {
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private let serverURL = "http://20.172.68.176:3000"

    // Use a valid JWT token from your Keychain
    private let testToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7ImVtYWlsIjoidGVzdC11c2VyQHRyaWNrbGUuYXBwIn0sImlhdCI6MTc2MTQ0MjgwMSwiZXhwIjoxNzYxNzAyMDAxfQ.Op5Y10Xnos95gLY2JzEg3n8guf72wQfyPz-6Ic2nsJc"

    func testConnection() {
        print(">ê Starting WebSocket Authentication Test")
        print("=" * 50)
        print("Server: \(serverURL)")
        print("Token: \(testToken.prefix(30))...")
        print("=" * 50)

        // Method 1: Try with query parameter only
        testMethod1()

        // Wait before trying next method
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.testMethod2()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.testMethod3()
        }
    }

    // MARK: - Method 1: Query Parameter
    func testMethod1() {
        print("\n=, TEST 1: Query Parameter (?token=xxx)")

        manager = SocketManager(
            socketURL: URL(string: serverURL)!,
            config: [
                .log(true),
                .forceWebsockets(true),
                .connectParams(["token": testToken])  // As query param
            ]
        )

        socket = manager?.defaultSocket
        setupListeners(testName: "Method 1")
        socket?.connect()
    }

    // MARK: - Method 2: Authorization Header
    func testMethod2() {
        print("\n=, TEST 2: Authorization Header (Bearer token)")

        disconnect()

        manager = SocketManager(
            socketURL: URL(string: serverURL)!,
            config: [
                .log(true),
                .forceWebsockets(true),
                .extraHeaders(["Authorization": "Bearer \(testToken)"])
            ]
        )

        socket = manager?.defaultSocket
        setupListeners(testName: "Method 2")
        socket?.connect()
    }

    // MARK: - Method 3: Auth Payload
    func testMethod3() {
        print("\n=, TEST 3: Socket.IO Auth Payload")

        disconnect()

        manager = SocketManager(
            socketURL: URL(string: serverURL)!,
            config: [
                .log(true),
                .forceWebsockets(true)
            ]
        )

        socket = manager?.defaultSocket
        setupListeners(testName: "Method 3")

        // Connect with auth payload
        socket?.connect(withPayload: ["token": testToken])
    }

    // MARK: - Setup Listeners
    private func setupListeners(testName: String) {
        // Success
        socket?.on(clientEvent: .connect) { data, ack in
            print(" [\(testName)] SUCCESS! Connected to server")
            print("   Data: \(data)")
        }

        // Error
        socket?.on(clientEvent: .error) { data, ack in
            print("L [\(testName)] ERROR event")
            print("   Data: \(data)")
        }

        // Connection Error
        socket?.on("connect_error") { data, ack in
            print("L [\(testName)] CONNECT_ERROR event")
            print("   Data: \(data)")
        }

        // Disconnect
        socket?.on(clientEvent: .disconnect) { data, ack in
            print("= [\(testName)] Disconnected")
            print("   Reason: \(data)")
        }

        // Catch all events
        socket?.onAny { event in
            print("=è [\(testName)] Event: \(event.event)")
            print("   Items: \(event.items ?? [])")
        }
    }

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
    }
}

// MARK: - How to Run This Test
/*
 To run this test:

 1. From Xcode:
    - Open your Frontend project
    - Add this file to your project if not already added
    - In ContentView.swift or any view, add:

      Button("Test WebSocket") {
          let test = WebSocketTest()
          test.testConnection()
      }

    - Run the app and tap the button
    - Check Xcode console for output

 2. From Command Line (macOS target):
    - Open Terminal
    - cd /Users/mac/Desktop/Frontend
    - Create a test runner:

      swift -I /path/to/SocketIO -framework SocketIO WebSocketTest.swift

 3. Add to existing app:
    - In GardenView.swift, add a test button temporarily:

      .onAppear {
          let test = WebSocketTest()
          test.testConnection()
      }

 Expected Output:
 - You'll see 3 tests run sequentially
 - One of them should connect successfully 
 - The successful method is what your backend expects
 - Copy that configuration to WebSocketManager.swift
*/
