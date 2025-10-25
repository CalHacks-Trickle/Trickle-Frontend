//
//  ContentView.swift
//  Frontend
//
//  Created by mac on 10/25/25.
//

import SwiftUI
import Security
import Combine

// MARK: - Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
}

struct SessionResponse: Codable {
    let user: UserData
    let expiresAt: String?

    struct UserData: Codable {
        let id: String
        let email: String
        let name: String?
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    private let service = "com.yourapp.frontend"

    func save(token: String) {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "jwt_token",
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "jwt_token",
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "jwt_token"
        ]

        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Network Service
class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://localhost:3000"

    func login(email: String, password: String) async throws -> String {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loginRequest = LoginRequest(email: email, password: password)
        request.httpBody = try JSONEncoder().encode(loginRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        return loginResponse.token
    }

    func getSession(token: String) async throws -> SessionResponse {
        let url = URL(string: "\(baseURL)/auth/session")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            }
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
        return sessionResponse
    }

    enum NetworkError: LocalizedError {
        case invalidResponse
        case httpError(Int)
        case unauthorized

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Invalid server response"
            case .httpError(let code):
                return "HTTP Error: \(code)"
            case .unauthorized:
                return "Unauthorized - Token expired or invalid"
            }
        }
    }
}

// MARK: - View Model
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var userEmail: String = ""
    @Published var sessionData: SessionResponse? = nil

    private let networkService = NetworkService.shared
    private let keychainManager = KeychainManager.shared

    init() {
        checkExistingToken()
    }

    func checkExistingToken() {
        if let token = keychainManager.getToken() {
            Task { @MainActor in
                await self.validateSession(token: token)
            }
        }
    }

    @MainActor
    func login(email: String, password: String) async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            let token = try await networkService.login(email: email, password: password)
            keychainManager.save(token: token)
            await self.validateSession(token: token)
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    @MainActor
    func validateSession(token: String) async {
        do {
            let session = try await networkService.getSession(token: token)
            self.sessionData = session
            self.userEmail = session.user.email
            self.isAuthenticated = true
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            keychainManager.deleteToken()
            self.isAuthenticated = false
            self.isLoading = false
        }
    }

    func logout() {
        keychainManager.deleteToken()
        self.isAuthenticated = false
        self.sessionData = nil
        self.userEmail = ""
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                HomeView(authViewModel: authViewModel)
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = "test-user@trickle.app"
    @State private var password = "MySecurePassword123"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.bottom, 30)

            Text("Welcome to Trickle")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 15) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal, 40)

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                Task {
                    await authViewModel.login(email: email, password: password)
                }
            }) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Login")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 40)
            .disabled(authViewModel.isLoading)

            Spacer()
        }
        .padding(.top, 100)
    }
}

// MARK: - Home View (After Login)
struct HomeView: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Authenticated!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let sessionData = authViewModel.sessionData {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("User Information:")
                            .font(.headline)

                        Text("Email: \(sessionData.user.email)")
                        Text("User ID: \(sessionData.user.id)")

                        if let name = sessionData.user.name {
                            Text("Name: \(name)")
                        }

                        if let expiresAt = sessionData.expiresAt {
                            Text("Session expires: \(expiresAt)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Logout")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
