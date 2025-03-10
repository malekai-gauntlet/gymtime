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
    
    // UI states
    @State private var isKeyboardVisible = false
    @FocusState private var focusedField: Field?
    @State private var showPassword = false
    
    // Error handling
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: isKeyboardVisible ? 0 : 60)
                    
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
                        
                        Text("Set your login to save your workouts.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                    
                    // Email field
                    TextField("Email", text: $email)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .email ? Color.gymtimeAccent : Color.white.opacity(0.1), lineWidth: focusedField == .email ? 2 : 1)
                                .animation(.easeInOut(duration: 0.1), value: focusedField)
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.gymtimeText)
                        .focused($focusedField, equals: .email)
                        .disabled(isLoading)
                    
                    // Password field with toggle
                    HStack(spacing: 0) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .password ? Color.gymtimeAccent : Color.white.opacity(0.1), lineWidth: focusedField == .password ? 2 : 1)
                                .animation(.easeInOut(duration: 0.1), value: focusedField)
                        )
                        .textContentType(.newPassword)
                        .foregroundColor(.gymtimeText)
                        .focused($focusedField, equals: .password)
                        .disabled(isLoading)
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
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
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Account")
                                    .font(.headline)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.gymtimeAccent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .disabled(isLoading)
                }
                .padding(.horizontal)
                .animation(.easeOut(duration: 0.25), value: isKeyboardVisible)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = true
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    isKeyboardVisible = false
                }
                
                // Set initial focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    focusedField = .email
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// Preview provider
struct AnonymousConversionView_Previews: PreviewProvider {
    static var previews: some View {
        AnonymousConversionView(isPresented: .constant(true))
    }
} 