//
//  BiometricsToggle.swift
//  
//
//  Created by 桜江輝 on 2023/05/04.
//

import SwiftUI
import LocalAuthentication

public struct BiometricsToggle: View {
    @EnvironmentObject var niceBiometrics: NiceBiometrics
    @Environment(\.scenePhase) var scenePhase

    public init() {}

    public var body: some View {
        Toggle(isOn: $niceBiometrics.toggleState) {
            Text(niceBiometrics.toggleTitle)
        }
        .disabled(niceBiometrics.shouldDisable)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                niceBiometrics.refresh()
            }
        }
    }
}

struct BiometricsToggle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BiometricsToggle()
                .environmentObject(NiceBiometrics.preview(.biometryAvailable))
                .previewDisplayName("Enabled")

            BiometricsToggle()
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryLockout))))
                .previewDisplayName("Lockout")
        }
    }
}
