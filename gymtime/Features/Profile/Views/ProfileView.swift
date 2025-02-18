/*
 * 🖼️ What is this file for?
 * -------------------------
 * This is like the layout blueprint for the Profile screen.
 * It defines how everything looks and is arranged on the profile page.
 * Think of it as an interior designer that arranges all the visual elements of the profile.
 */


import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    let username: String
    let tapOnLinkAction: (URL) -> Void
    
    var user: User? {
        viewModel.user
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text(viewModel.username ?? "")
                .font(.title)
                .leadingAlignment()
            
            Text(viewModel.displayName ?? "")
                .font(.title2)
                .leadingAlignment()
            
            Text(viewModel.bio ?? "")
            
            VStack {
                Text(viewModel.publicReposText ?? "")
                    .leadingAlignment()
                Text(viewModel.publicGistsText ?? "")
                    .leadingAlignment()
                Text(viewModel.followersText ?? "")
                    .leadingAlignment()
                Text(viewModel.followingText ?? "")
                    .leadingAlignment()
            }
            
            Button("Open Github website to see more details") {
                if let url = user?.htmlURL {
                    tapOnLinkAction(url)
                }
            }
            .leadingAlignment()
            
            Spacer()
        }
        .padding()
        .onAppear(perform: {
            viewModel.getUser(username: username)
        })
        .navigationBarTitle("Profile", displayMode: .inline)
    }
}
