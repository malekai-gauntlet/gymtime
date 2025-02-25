// 📄 Provides the signup form interface with email and password fields
import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var isKeyboardVisible = false
    @FocusState private var focusedField: Field?
    @State private var isViewAppeared = false
    
    enum Field {
        case email
        case password
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: isKeyboardVisible ? 0 : 100)
                    
                // Email field
                TextField("Email", text: $viewModel.email)
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
                    .disabled(viewModel.isLoading)
                    .id("email-field") // Add stable ID for focus
                
                // Password field
                SecureField("Password", text: $viewModel.password)
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
                    .disabled(viewModel.isLoading)
                    .id("password-field") // Add stable ID for focus
                
                // Error message
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign Up button
                Button(action: {
                    Task {
                        await viewModel.signUp()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign Up")
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
                .disabled(viewModel.isLoading)
                
                // Switch to login
                Button(action: {
                    viewModel.switchFlow()
                }) {
                    Text("Already have an account? Log In")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.15))
                .foregroundColor(.gymtimeAccent)
                .cornerRadius(12)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            .animation(.easeOut(duration: 0.25), value: isKeyboardVisible)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Set flag that view has appeared
            isViewAppeared = true
            
            // Set focus after a slight delay to ensure view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .email
            }
            
            // Set up keyboard notifications
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                isKeyboardVisible = false
            }
        }
        .onDisappear {
            // Clean up by removing focus when view disappears
            focusedField = nil
            isViewAppeared = false
        }
        // Add a tap gesture to handle taps on the view
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                // Only respond if no field is currently focused
                if focusedField == nil && isViewAppeared {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = .email
                    }
                }
            }
        )
    }
}
