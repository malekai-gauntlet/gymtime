/*
 * 🗺️ What is this file for?
 * -------------------------
 * This is like a traffic controller for the Profile section of your app.
 * It manages navigation between different profile-related screens.
 * Think of it as a GPS that helps users move between different parts of their profile.
 */

import SwiftUI

struct ProfileCoordinator: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    
    let username: String
    
    var body: some View {
        NavigationView {
            ProfileView(username: username, tapOnLinkAction: { url in
                openURL(url)
            })
            .navigationBarItems(leading: Button("Close", action: {
                presentationMode.wrappedValue.dismiss()
            }))
        }
    }
}
