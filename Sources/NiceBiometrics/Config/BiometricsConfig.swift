//
//  BiometricsConfig.swift
//  
//
//  Created by 桜江輝 on 2023/07/13.
//

import Foundation
import LocalAuthentication

public struct BiometricsConfig {
    let keychainKey: String
    let policy: LAPolicy
    let localizedReason: LocalizedReason
    let fallbackOption: FallbackOption
    let requiresAuthenticationToDisable: Bool
    var previewMode: PreviewMode?

    public init(
        keychainKey: String,
        policy: LAPolicy,
        localizedReason: LocalizedReason,
        fallbackOption: FallbackOption,
        requiresAuthenticationToDisable: Bool,
        previewMode: PreviewMode? = nil) {
            self.keychainKey = keychainKey
            self.policy = policy
            self.localizedReason = localizedReason
            self.fallbackOption = fallbackOption
            self.requiresAuthenticationToDisable = requiresAuthenticationToDisable
            self.previewMode = previewMode
        }
}
