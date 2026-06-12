//
//  SDKManager.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Combine
import ElegaiterSDK
import Foundation

/// SDK 초기화 상태 (Android `InitState` 대응)
enum SDKInitState: Equatable {
    case loading
    case success
    case error(ElegaiterInitResult, String?)
}

/// SDK 인스턴스 및 라이선스 검증 초기화 관리
final class SDKManager: ObservableObject {
    private enum Constants {
        static let apiKeyInfoPlistKey = "ElegaiterSDKApiKey"
    }

    static let shared = SDKManager()

    @Published private(set) var initState: SDKInitState = .loading

    private var _sdk: ElegaiterSdk?
    private var initializationTask: Task<Void, Never>?

    private init() {}

    /// 라이선스 검증 포함 SDK 초기화 시작
    func preload() {
        guard case .loading = initState, initializationTask == nil else {
            if case .error = initState {
                retry()
            }
            return
        }
        startInitialization()
    }

    /// 초기화 재시도
    func retry() {
        initializationTask?.cancel()
        initializationTask = nil
        _sdk = nil
        initState = .loading
        startInitialization()
    }

    /// 초기화 완료 후 SDK 인스턴스
    var sdk: ElegaiterSdk {
        guard let sdk = _sdk else {
            fatalError("[SDKManager] SDK is not initialized. Wait for license validation to succeed.")
        }
        return sdk
    }

    private func startInitialization() {
        guard let apiKey = resolveApiKey() else {
            initState = .error(
                .invalidLicense,
                "Info.plist에 '\(Constants.apiKeyInfoPlistKey)'가 설정되어 있지 않습니다."
            )
            return
        }

        initializationTask = Task { @MainActor in
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                Elegaiter.initialize(apiKey: apiKey) { [weak self] success, result, message in
                    guard let self else {
                        continuation.resume()
                        return
                    }
                    if success, let sdk = Elegaiter.sdk {
                        self._sdk = sdk
                        self.initState = .success
                    } else {
                        self._sdk = nil
                        self.initState = .error(result, message)
                    }
                    self.initializationTask = nil
                    continuation.resume()
                }
            }
        }
    }

    private func resolveApiKey() -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: Constants.apiKeyInfoPlistKey) as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
