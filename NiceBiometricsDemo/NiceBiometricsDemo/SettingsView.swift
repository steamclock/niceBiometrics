//
//  SettingsView.swift
//  NiceBiometricsDemo
//
//  Created by 桜江輝 on 2023/05/04.
//

import NiceBiometrics
import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var niceBiometrics: NiceBiometrics

    var body: some View {
        List {
            BiometricsToggleSection()
                .environmentObject(niceBiometrics)

            Section {
                Button {
                    navigationManager.showLogin()
                } label: {
                    Text("Log Out")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview(.biometryAvailable))
                .previewDisplayName("Available")

            SettingsView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotEnrolled))))
                .previewDisplayName("Not Enrolled")

            SettingsView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotAvailable))))
                .previewDisplayName("Not Available")

            SettingsView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.passcodeNotSet))))
                .previewDisplayName("Passcode Not Set")

            SettingsView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryLockout))))
                .previewDisplayName("Lockout")
        }
    }
}
