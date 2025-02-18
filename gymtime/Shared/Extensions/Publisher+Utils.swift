/*
 * 📬 What is this file for?
 * -------------------------
 * This is like a smart message delivery system for your app.
 * It helps manage data streams and makes it easier to work with optional values.
 * Think of it as a mail sorting system that helps organize incoming data in your app.
 */

//
//  Publisher+Utils.swift
//  SwiftUI-MVVM-C
//
//  Created by Nguyen Cong Huy on 5/18/21.
//

import Combine

extension Publisher {
    func optionalize() -> Publishers.Map<Self, Self.Output?> {
        map({ Optional.some($0) })
    }
}
