import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.updateProfile(username: username, fullName: fullName)
                                dismiss()
                            } catch {
                                showingError = true
                            }
                        }
                    }
                    .disabled(username.isEmpty || fullName.isEmpty)
                }
            }
            .alert("Failed to Update Profile", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error ?? "Please try again")
            }
        }
        .onAppear {
            // Initialize fields with current values
            username = viewModel.username ?? ""
            fullName = viewModel.displayName ?? ""
        }
    }
} 