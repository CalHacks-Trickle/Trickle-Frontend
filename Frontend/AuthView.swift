import SwiftUI

// Codable struct to match the JSON for the REQUEST
struct AuthRequest: Codable {
    let email: String
    let password: String
}

// Codable struct to match the JSON for the RESPONSE
struct AuthResponse: Codable {
    let message: String
}

struct AuthView: View {
    // State for the form fields
    @State private var email = ""
    @State private var password = ""
    
    // State to show success/error messages from the server
    @State private var serverMessage = ""
    
    // Environment property to dismiss the sheet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // Form makes it look nice on macOS
        Form {
            Section(header: Text("Create Your Account")) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // SecureField hides the password
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section {
                Button("Register", action: registerUser)
                    .buttonStyle(.borderedProminent)
            }
            
            // Display the server's response
            if !serverMessage.isEmpty {
                Text(serverMessage)
                    .foregroundColor(serverMessage.contains("successfully") ? .green : .red)
            }
        }
        .padding()
        .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
    }
    
    func registerUser() {
        // 1. Set up the URL
        guard let url = URL(string: "http://localhost:3000/auth/register") else {
            self.serverMessage = "Error: Invalid URL"
            return
        }
        
        // 2. Create the request body
        let body = AuthRequest(email: email, password: password)
        
        // 3. Set up the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 4. Encode the body
        guard let httpBody = try? JSONEncoder().encode(body) else {
            self.serverMessage = "Error: Could not encode request"
            return
        }
        request.httpBody = httpBody
        
        // 5. Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                DispatchQueue.main.async {
                    self.serverMessage = "Network Error: \(error.localizedDescription)"
                }
                return
            }
            
            // Handle server response
            guard let data = data else {
                DispatchQueue.main.async {
                    self.serverMessage = "Error: No data from server"
                }
                return
            }
            
            // Decode the server's JSON response
            if let decodedResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.serverMessage = decodedResponse.message
                    // If success, wait 2 seconds and dismiss the sheet
                    if decodedResponse.message.contains("successfully") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            dismiss() // This closes the sheet
                        }
                    }
                }
            } else {
                // Handle cases where the JSON doesn't match AuthResponse (e.g., error)
                let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    self.serverMessage = "Server Error: \(errorString)"
                }
            }
        }.resume() // Don't forget to start the task!
    }
}

#Preview {
    AuthView()
}
