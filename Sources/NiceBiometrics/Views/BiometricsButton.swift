//
//  BiometricsButton.swift
//  
//
//  Created by 桜江輝 on 2023/07/03.
//

import SwiftUI
import LocalAuthentication

public struct BiometricsButton: View {
    @EnvironmentObject var niceBiometrics: NiceBiometrics
    @Environment(\.scenePhase) var scenePhase
    
    let completion: () -> Void
    let passwordLogin: () -> Void

    public init(completion: @escaping () -> Void, passwordLogin: @escaping () -> Void) {
        self.completion = completion
        self.passwordLogin = completion
    }

    public var body: some View {
        Button {
            if niceBiometrics.isBiometricsEnabled && niceBiometrics.canAuthenticate {
                Task {
                    await niceBiometrics.authenticate(purpose: .login) {
                        completion()
                    }
                }
            } else {
                passwordLogin()
            }
        } label: {
            HStack {
                Spacer()
                Text(niceBiometrics.loginTitle)
                Spacer()
            }
            .frame(minHeight: 44)
            .foregroundColor(.white)
            .background(.blue.opacity(0.8))
            .cornerRadius(8)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                niceBiometrics.refresh()
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BiometricsButton {

            } passwordLogin: {

            }
            .environmentObject(NiceBiometrics.preview(.biometryAvailable))
            .previewDisplayName("Available")

            BiometricsButton {

            } passwordLogin: {

            }
            .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotAvailable))))
            .previewDisplayName("Not Available")
        }
    }
}
