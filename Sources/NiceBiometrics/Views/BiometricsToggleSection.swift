//
//  BiometricsToggleSection.swift
//  
//
//  Created by 桜江輝 on 2023/07/03.
//

import SwiftUI
import LocalAuthentication

public struct BiometricsToggleSection: View {
    @EnvironmentObject var niceBiometrics: NiceBiometrics

    public init() {}
    
    public var body: some View {
        Section {
            BiometricsToggle()

            if niceBiometrics.shouldShowSettingsButton {
                Button("Fix in Settings") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        } header: {
            Text("Security")
        } footer: {
            Text(niceBiometrics.hintMessage)
        }
    }
}

struct BiometricsToggleSection_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                BiometricsToggleSection()
                    .environmentObject(NiceBiometrics.preview(.biometryAvailable))
            }
            .previewDisplayName("Available")

            List {
                BiometricsToggleSection()
                    .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotEnrolled))))
            }
            .previewDisplayName("Not Enrolled")

            List {
                BiometricsToggleSection()
                    .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotAvailable))))
            }
            .previewDisplayName("Not Available")

            List {
                BiometricsToggleSection()
                    .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.passcodeNotSet))))
            }
            .previewDisplayName("Passcode Not Set")

            List {
                BiometricsToggleSection()
                    .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryLockout))))
            }
            .previewDisplayName("Lockout")
        }
    }
}
