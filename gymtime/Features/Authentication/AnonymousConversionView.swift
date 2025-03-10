import SwiftUI

struct AnonymousConversionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @Binding var isPresented: Bool
    @StateObject private var viewModel = AuthenticationViewModel(coordinator: AppCoordinator())
    
    // Validation states
    @State private var isEmailValid = false
    @State private var isPasswordValid = false
    
    // Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header section
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkerboard")
                            .font(.system(size: 40))
                            .foregroundColor(.gymtimeAccent)
                            .padding(.bottom, 8)
                        
                        Text("Don't Lose Your Progress")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Set your account & password so that if you get logged out you can still access your workouts.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Form fields
                    VStack(spacing: 16) {
                        // Email field
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(.horizontal)
                        
                        // Password field
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        // Save Account button
                        Button(action: {
                            Task {
                                isLoading = true
                                await viewModel.convertAnonymousUser(email: email, password: password)
                                if viewModel.error == nil {
                                    isPresented = false
                                } else {
                                    showError = true
                                    errorMessage = viewModel.error?.localizedDescription ?? "An error occurred"
                                }
                                isLoading = false
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gymtimeAccent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal)
                        
                        // Maybe Later button
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Maybe Later")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Benefits section
                    VStack(spacing: 16) {
                        Text("Benefits of saving your account:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        // Benefits list
                        VStack(alignment: .leading, spacing: 12) {
                            benefitRow(icon: "lock.shield", text: "Secure your workout history")
                            benefitRow(icon: "arrow.triangle.2.circlepath", text: "Access from any device")
                            benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress over time")
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gymtimeAccent)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// Preview provider
struct AnonymousConversionView_Previews: PreviewProvider {
    static var previews: some View {
        AnonymousConversionView(isPresented: .constant(true))
    }
} 