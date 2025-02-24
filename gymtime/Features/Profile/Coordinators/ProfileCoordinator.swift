/*
 * 🗺️ What is this file for?
 * -------------------------
 * This coordinator is currently simple but prepared for future expansion.
 * When we add more profile-related screens (e.g. detailed workout history,
 * achievements, settings, account management), this coordinator will manage
 * the navigation between them all.
 * 
 * For now it just shows the main ProfileView, but keeping this structure
 * makes it easier to add more navigation logic later without restructuring.
 */

import SwiftUI

struct ProfileCoordinator: View {
    var body: some View {
        ProfileView()
    }
}
