//
//  ContentView.swift
//  NiceBiometricsDemo
//
//  Created by 桜江輝 on 2023/05/04.
//

import NiceBiometrics
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            LoginView()
                .navigationDestination(for: NavigationKey.self) { value in
                    if value == .settings {
                        SettingsView()
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NavigationManager())
            .environmentObject(NiceBiometrics.preview(.biometryAvailable))
    }
}
