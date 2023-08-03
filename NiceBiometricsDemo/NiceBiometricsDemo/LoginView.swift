//
//  LoginView.swift
//  NiceBiometricsDemo
//
//  Created by 桜江輝 on 2023/05/04.
//

import NiceBiometrics
import SwiftUI
import LocalAuthentication

enum LoginField: Hashable {
    case username
    case password
}

struct LoginView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var niceBiometrics: NiceBiometrics

    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focus: LoginField?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack {
                    Image("logo")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .cornerRadius(8)
                        .padding(.trailing, 8)
                    Text("Nice Biometrics")
                        .font(.largeTitle)
                }
                .padding(32)

                Form {
                    TextField("Username", text: $username)
                        .focused($focus, equals: .username)
                        .font(.system(size: 18))
                    SecureField("Password", text: $password)
                        .focused($focus, equals: .password)
                        .font(.system(size: 18))
                }
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .scrollDisabled(true)

                BiometricsButton {
                    navigationManager.showSettings()
                } passwordLogin: {
                    navigationManager.showSettings()
                }
                .environmentObject(niceBiometrics)
                .padding(32)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.gray.opacity(0.1))
        .onTapGesture {
            focus = nil
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview(.biometryAvailable))
                .previewDisplayName("Enabled")

            LoginView()
                .environmentObject(NavigationManager())
                .environmentObject(NiceBiometrics.preview( .biometryUnavailable(LAError(.biometryNotAvailable))))
                .previewDisplayName("Disabled")
        }
    }
}
