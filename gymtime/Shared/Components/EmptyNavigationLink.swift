/*
 * 🚪 What is this file for?
 * -------------------------
 * This is a utility for programmatic navigation that isn't currently being used,
 * but will be valuable for future features such as:
 * - Navigating to workout details after completing a workout
 * - Showing achievement details when a new milestone is reached
 * - Redirecting to specific screens after authentication
 * 
 * Unlike regular NavigationLink, this is invisible and can be triggered
 * programmatically from anywhere in your code (not just user taps).
 */

//
//  EmptyNavigationLink.swift
//  SwiftUI-MVVM-C
//
//  Created by Nguyen Cong Huy on 5/18/21.
//

import SwiftUI

struct EmptyNavigationLink<Destination>: View where Destination: View {
    let destination: Destination
    let isActive: Binding<Bool>
    
    init(destination: Destination, isActive: Binding<Bool>) {
        self.destination = destination
        self.isActive = isActive
    }
    
    init<T>(destination: Destination, selectedItem: Binding<T?>) {
        self.destination = destination
        self.isActive = selectedItem.map(valueToMappedValue: { $0 != nil }, mappedValueToValue: { _ in nil })
    }
    
    var body: some View {
        NavigationLink(value: "empty") { EmptyView() }
            .navigationDestination(isPresented: isActive) {
                destination
            }
    }
}
