import Combine
import KeychainSwift
import LocalAuthentication
import UIKit
import SwiftUI

@MainActor public class NiceBiometrics: ObservableObject {
    let config: BiometricsConfig

    @Published private(set) var isBiometricsEnabled: Bool {
        didSet {
            KeychainSwift().set(isBiometricsEnabled, forKey: config.keychainKey)
            setLoginTitle(from: nil)
        }
    }

    @Published private(set) var type: LABiometryType = .none {
        didSet {
            setToggleTitle(from: type)
        }
    }

    @Published var toggleState: Bool = false
    @Published var toggleTitle: String = ""
    @Published var loginTitle: String = ""
    @Published var errorMessage: String = ""
    @Published var shouldShowSettingsButton = false
    @Published var hintMessage: String = ""
    @Published var shouldDisable = false

    var currentError: Error?
    var canAuthenticate: Bool { return currentError == nil }

    private var authInProgress = false
    private var cancellables = Set<AnyCancellable>()

    public init(config: BiometricsConfig) {
        self.config = config

        if let previewMode = config.previewMode {
            switch previewMode {
            case .biometryAvailable:
                self.isBiometricsEnabled = true
                self.toggleState = true
                self.type = .faceID
                handle(nil)
            case .biometryUnavailable(let error):
                self.isBiometricsEnabled = false
                self.toggleState = false
                self.type = .touchID
                handle(error)
            }
        } else {
            self.isBiometricsEnabled = KeychainSwift().getBool(config.keychainKey) ?? false
            self.toggleState = self.isBiometricsEnabled
            self.refresh()

            self.$toggleState
                .dropFirst()
                .removeDuplicates()
                .sink { [weak self] newValue in
                    guard let self = self, !self.authInProgress, self.canAuthenticate else { return }
                    Task {
                        await self.authenticate(purpose: .toggle)
                    }
                }.store(in: &cancellables)
        }
    }

    public static func preview(_ previewMode: PreviewMode) -> NiceBiometrics {
        let config = BiometricsConfig(
            keychainKey: "preview.demo.nicebiometrics",
            policy: .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: .standard,
            fallbackOption: .disabled,
            requiresAuthenticationToDisable: false,
            previewMode: previewMode
        )
        return NiceBiometrics(config: config)
    }

    public func authenticate(localizedReason: String? = nil, purpose: AuthenticationPurpose, completion: (() -> Void)? = nil) async {
        authInProgress = true
        defer {
            authInProgress = false
        }

        if purpose == .toggle && isBiometricsEnabled && !config.requiresAuthenticationToDisable {
            handleAuthenticationSuccess(purpose, completion)
        } else {
            await attemptAuthentication(purpose, completion)
        }
    }

    private func attemptAuthentication(_ purpose: AuthenticationPurpose, _ completion: (() -> Void)?) async {
        do {
            let context = LAContext()

            context.localizedFallbackTitle = determineLocalizedFallbackTitle()
            let reason = determineLocalizedReason(context: context)

            try await context.evaluatePolicy(config.policy, localizedReason: reason)
            context.invalidate()

            handleAuthenticationSuccess(purpose, completion)
        } catch {
            handleAuthenticationError(purpose, error)
        }
    }

    private func handleAuthenticationSuccess(_ purpose: AuthenticationPurpose, _ completion: (() -> Void)?) {
        switch purpose {
        case .login:
            isBiometricsEnabled = true
            toggleState = true
        case .toggle:
            isBiometricsEnabled = !isBiometricsEnabled
        }

        completion?()
    }

    private func handleAuthenticationError(_ purpose: AuthenticationPurpose, _ error: Error) {
        switch purpose {
        case .login:
            break
        case .toggle:
            toggleState = !toggleState
        }

        handle(error)
    }

    private func determineLocalizedFallbackTitle() -> String? {
        switch config.fallbackOption {
        case .disabled:
            return ""
        case .standard:
            return nil
        case .custom(let title):
            return title
        }
    }

    private func determineLocalizedReason(context: LAContext) -> String {
        switch config.localizedReason {
        case .standard:
            return "Please authenticate using \(context.biometryType.title) to continue."
        case .custom(let title):
            return title
        }
    }

    public func refresh() {
        let context = LAContext()
        var error: NSError?

        defer {
            context.invalidate()
        }

        context.canEvaluatePolicy(config.policy, error: &error)
        type = context.biometryType

        handle(error)
    }

    private func handle(_ error: Error?) {
        if let error = error as? LAError, error.code == .userCancel {
            return
        }

        currentError = error

        setLoginTitle(from: error)
        setMessages(from: error)

        setShouldDisable(from: error)
    }

    private func setToggleTitle(from biometryType: LABiometryType) {
        if biometryType != .none {
            toggleTitle = "Use \(biometryType.title)"
        } else {
            toggleTitle = "Biometrics Unavailable"
        }
    }

    private func setLoginTitle(from error: Error?) {
        if error == nil && type != .none && isBiometricsEnabled {
            loginTitle = "Sign in with \(type.title)"
        } else {
            loginTitle = "Sign In"
        }
    }

    private func setMessages(from error: Error?) {
        guard let error = error as? LAError else {
            errorMessage = ""
            shouldShowSettingsButton = false
            hintMessage = ""
            return
        }

        errorMessage = error.localizedDescription

        switch error.code {
        case .biometryLockout:
            shouldShowSettingsButton = false
            hintMessage = "\(type.title) is locked from too many failed attempts. Please go the Settings app and re-enter your passcode."
        case .biometryNotAvailable:
            shouldShowSettingsButton = true
            hintMessage = "\(type.title) is not enabled for this app."
        case .biometryNotEnrolled:
            shouldShowSettingsButton = false
            hintMessage = "You have not turned on \(type.title) on your device yet. Please setup \(type.title) using the Settings app."
        case .passcodeNotSet:
            shouldShowSettingsButton = false
            hintMessage = "Device passcode is a prerequisite for using \(type.title). Please create a passcode from the Settings app."
        default:
            shouldShowSettingsButton = false
            break
        }
    }

    private func setShouldDisable(from error: Error?) {
        guard let error = error as? LAError else {
            shouldDisable = false
            return
        }

        switch error.code {
        case .biometryLockout, .biometryNotAvailable, .biometryNotEnrolled, .passcodeNotSet:
            shouldDisable = true
        default:
            shouldDisable = false
        }
    }
}
