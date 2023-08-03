//
//  PreviewMode.swift
//  
//
//  Created by 桜江輝 on 2023/07/03.
//

import Foundation
import LocalAuthentication

public enum PreviewMode {
    case biometryAvailable
    case biometryUnavailable(LAError)
}
