/*
 * 📦 What is this file for?
 * -------------------------
 * Think of this as an organized storage box for your app's data.
 * It helps manage and organize different pieces of data your app needs.
 * Just like a well-organized toolbox, it keeps everything in its proper place and easy to find.
 */

//
//  Container.swift
//  SwiftUI-MVVM-C
//
//  Created by Nguyen Cong Huy on 5/18/21.
//

import Foundation

/// Wrap a struct to avoid compile error when have a struct as a property in a same type struct. For example, a property forkFromRepo with type Repo in a Repo struct.
struct Container<T: Codable>: Codable {
    private var values: [T] = []
    
    init(value: T) {
        self.value = value
    }
    
    var value: T {
        get {
            values.first!
        }
        
        set {
            values = [newValue]
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(T.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
