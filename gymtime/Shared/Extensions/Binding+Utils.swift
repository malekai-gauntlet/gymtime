/*
 * 🎮 What is this file for?
 * -------------------------
 * Think of this as a super-powered remote control for your app's data.
 * It helps you control and modify values in your SwiftUI views more easily.
 * For example, when you need to update text fields or toggle switches in your app.
 */

//
//  Binding+Utils.swift
//  
//
//  Created by Huy Nguyen on 9/30/20.
//

import SwiftUI

extension Binding {
    func map<MappedValue>(
        valueToMappedValue: @escaping (Value) -> MappedValue,
        mappedValueToValue: @escaping (MappedValue) -> Value
    ) -> Binding<MappedValue> {
        Binding<MappedValue>.init { () -> MappedValue in
            return valueToMappedValue(wrappedValue)
        } set: { mappedValue in
            wrappedValue = mappedValueToValue(mappedValue)
        }
    }
    
    func onSet(_ action: @escaping (Value) -> Void) -> Binding<Value> {
        return Binding { () -> Value in
            return wrappedValue
        } set: { value in
            action(value)
            wrappedValue = value
        }
    }
}

func ??<T>(binding: Binding<T?>, fallback: T) -> Binding<T> {
    return Binding(get: {
        binding.wrappedValue ?? fallback
    }, set: {
        binding.wrappedValue = $0
    })
}
