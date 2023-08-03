//
//  LABiometryType+Extensions.swift
//  
//
//  Created by 桜江輝 on 2023/05/04.
//

import LocalAuthentication

extension LABiometryType {
    var title: String {
        switch self {
        case .none:
            return "None"
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        @unknown default:
            return "Unknown"
        }
    }
}
