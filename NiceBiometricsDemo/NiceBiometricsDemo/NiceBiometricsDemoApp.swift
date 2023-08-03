//
//  NiceBiometricsDemoApp.swift
//  NiceBiometricsDemo
//
//  Created by 桜江輝 on 2023/05/04.
//

import NiceBiometrics
import SwiftUI

@main
struct NiceBiometricsDemoApp: App {
    @StateObject var navigationManager = NavigationManager()
    @StateObject var niceBiometrics = NiceBiometrics(config: BiometricsConfig(
        keychainKey: "demo.nicebiometrics",
        policy: .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: .standard,
        fallbackOption: .disabled,
        requiresAuthenticationToDisable: false
    ))

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(navigationManager)
                .environmentObject(niceBiometrics)
        }
    }
}
