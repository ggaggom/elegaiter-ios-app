//
//  SettingViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// 설정 화면 ViewModel
/// 
/// Android의 `SettingViewModel`을 Swift로 변환
/// - 다이얼로그 상태 관리
/// - 로그아웃, 회원 탈퇴, 블루투스 재연결 처리
@MainActor
class SettingViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private let tempAuthStorage: TempAuthStorage
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = SettingUiState()
    
    /// 이벤트 스트림
    private let eventSubject = PassthroughSubject<SettingEvent, Never>()
    var events: AnyPublisher<SettingEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    /// 네트워크 온라인 상태
    @Published var isOnline: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        networkMonitor: NetworkMonitor = NetworkMonitorImpl(),
        tempAuthStorage: TempAuthStorage = .shared
    ) {
        self.sdk = sdk
        self.networkMonitor = networkMonitor
        self.tempAuthStorage = tempAuthStorage
        
        observeNetworkState()
    }
    
    // MARK: - Network Monitoring
    
    private func observeNetworkState() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
    }
    
    // MARK: - Dialog Management
    
    /// 다이얼로그 표시
    func showDialog(_ dialog: SettingDialogState) {
        uiState.dialogState = dialog
    }
    
    /// 다이얼로그 닫기
    func dismissDialog() {
        uiState.dialogState = .none
    }
    
    // MARK: - Actions
    
    /// 로그아웃 처리
    func onLogout() {
        Task {
            await sdk.authManager.logout()
            eventSubject.send(.restartApp)
        }
    }
    
    /// 블루투스 연결 해제
    func onDisconnect() {
        Task {
            await sdk.bleManager.disconnect()
        }
    }
    
    /// 비밀번호 재인증 (회원정보 수정 진입 전)
    /// - Parameters:
    ///   - password: 확인할 비밀번호
    ///   - completion: 성공 여부 콜백
    func onVerifyPw(password: String, completion: @escaping (Bool) -> Void) {
        Task {
            let result = await sdk.authManager.verifyCurrentPassword(password: password)
            let success: Bool
            if case .success = result {
                tempAuthStorage.setPassword(password)
                success = true
            } else {
                success = false
            }
            completion(success)
        }
    }

    /// 회원 탈퇴 처리
    /// - Parameter password: 비밀번호
    /// - Returns: 성공 여부
    func onWithdraw(password: String) async -> Bool {
        let result = await sdk.authManager.deleteAccount(password: password)
        
        switch result {
        case .success:
            eventSubject.send(.restartApp)
            return true
        case .failure:
            return false
        }
    }
    
    // MARK: - Navigation
    
    func navigateToAchievement() {
        coordinator?.settingRouter.navigate(to: .achievement)
    }
    
    func navigateToAccountEdit() {
        coordinator?.settingRouter.navigate(to: .accountEdit)
    }
    
    func navigateToStepGoal() {
        coordinator?.settingRouter.navigate(to: .stepGoal)
    }
    
    func navigateToDeviceError() {
        coordinator?.settingRouter.navigate(to: .deviceError)
    }
    
    func navigateToTerms() {
        coordinator?.settingRouter.navigate(to: .terms)
    }
    
    func navigateToThreshold() {
        // Setting에서 Threshold로 이동 시 settingPath 사용
        coordinator?.navigateInSetting(to: .threshold)
    }
    
    func navigateToResetPassword() {
        coordinator?.settingRouter.navigate(to: .resetPassword)
    }
    
    func navigateToJawsSearch() {
        // Setting에서 JawsSearch로 이동 시 settingPath 사용 (Threshold와 동일)
        coordinator?.navigateInSetting(to: .jawsSearch)
    }
    
    func navigateToAppLanguage() {
        coordinator?.settingRouter.navigate(to: .appLanguage)
    }
}

// MARK: - UI State

/// 설정 화면 UI 상태
struct SettingUiState {
    /// 다이얼로그 상태
    var dialogState: SettingDialogState = .none
}

/// 설정 화면 다이얼로그 상태
enum SettingDialogState {
    case none
    case logout
    case disconnect
    case withdraw
    case verifyPw
    case resetPassword
    case terms
}

/// 설정 화면 이벤트
enum SettingEvent {
    case restartApp
}
