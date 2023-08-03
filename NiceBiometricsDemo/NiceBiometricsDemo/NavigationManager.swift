//
//  NavigationManager.swift
//  NiceBiometricsDemo
//
//  Created by 桜江輝 on 2023/07/03.
//

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()

    func showLogin() {
        path.removeLast(path.count)
    }

    func showSettings() {
        path.append(NavigationKey.settings)
    }
}

enum NavigationKey {
    case settings
}
