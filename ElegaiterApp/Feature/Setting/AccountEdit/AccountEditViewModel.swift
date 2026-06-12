//
//  AccountEditViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// 계정 정보 수정 ViewModel
/// 
/// Android의 `AccountEditViewModel`을 Swift로 변환
/// - 사용자 프로필 조회 및 업데이트
/// - 폼 검증
@MainActor
class AccountEditViewModel: ObservableObject {
    // MARK: - Dependencies
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private let tempAuthStorage: TempAuthStorage
    weak var coordinator: AppCoordinator?
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = AccountEditUiState()
    
    /// 이벤트 스트림
    private let eventSubject = PassthroughSubject<AccountEditEvent, Never>()
    var events: AnyPublisher<AccountEditEvent, Never> {
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
        loadUserProfile()
    }
    
    // MARK: - Network Monitoring
    
    private func observeNetworkState() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
    }
    
    // MARK: - Profile Loading
    
    /// 사용자 프로필 로드
    private func loadUserProfile() {
        Task {
            let result = await sdk.authManager.getUserProfile()
            
            switch result {
            case .success(let profile):
                uiState.initialProfile = profile
                uiState.name = profile.name
                uiState.phone = profile.phone
                uiState.height = String(format: "%.0f", profile.height)
                uiState.weight = String(format: "%.0f", profile.weight)
                uiState.gender = profile.gender
                uiState.birthday = profile.birthday
            case .failure:
                // 네트워크 비활성 상태에서 정보 획득 실패 시 토스트 후 이전 화면으로 돌아가기
                eventSubject.send(.showToast("edit_get_profile_failed".localized()))
                if !isOnline {
                    // 토스트 표시 후 약간의 지연을 두고 이전 화면으로 돌아가기
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 대기
                    eventSubject.send(.navigateBack)
                }
            }
        }
    }
    
    // MARK: - Input Handling
    
    /// 입력 필드 값 변경
    /// - Parameters:
    ///   - field: 필드 이름
    ///   - value: 새 값
    func onValueChange(field: String, value: String) {
        switch field {
        case "name":
            uiState.name = value
        case "phone":
            uiState.phone = value
        case "height":
            uiState.height = value
        case "weight":
            uiState.weight = value
        case "gender":
            uiState.gender = value
        case "birthday":
            uiState.birthday = value
        default:
            break
        }
    }
    
    // MARK: - Save
    
    /// 프로필 저장
    func onSaveClick() {
        guard isOnline else {
            eventSubject.send(.showToast("error_network_connection".localized()))
            return
        }
        
        guard uiState.isSaveEnabled else {
            return
        }
        
        uiState.isSaving = true
        
        Task {
            var passwordHolder: String? = tempAuthStorage.consumePassword()
            guard let password = passwordHolder else {
                eventSubject.send(.showToast("edit_session_expired".localized()))
                eventSubject.send(.navigateBack)
                uiState.isSaving = false
                return
            }

            defer {
                tempAuthStorage.wipePassword(&passwordHolder)
                uiState.isSaving = false
            }

            let updatedProfile = UserProfile(
                name: uiState.name,
                gender: uiState.gender,
                birthday: uiState.birthday,
                phone: uiState.phone,
                height: Float(uiState.height) ?? 0,
                weight: Float(uiState.weight) ?? 0,
                password: password
            )
            
            let result = await sdk.authManager.updateUserProfile(updatedProfile: updatedProfile)
            
            switch result {
            case .success:
                eventSubject.send(.showToast("edit_completed_toast".localized()))
                eventSubject.send(.saveSuccess)
            case .failure:
                eventSubject.send(.showToast("edit_failed_toast".localized()))
            }
        }
    }
    
    // MARK: - Navigation
    
    func navigateBack() {
        guard let coordinator = coordinator else { return }
        coordinator.pop(in: Binding(
            get: { coordinator.settingPath },
            set: { coordinator.settingPath = $0 }
        ))
    }
}

// MARK: - UI State

/// 계정 정보 수정 UI 상태
struct AccountEditUiState {
    /// 초기 프로필 (변경사항 비교용)
    var initialProfile: UserProfile? = nil
    
    /// 이름
    var name: String = ""
    /// 전화번호
    var phone: String = ""
    /// 키
    var height: String = ""
    /// 몸무게
    var weight: String = ""
    /// 성별 ("M" 또는 "F")
    var gender: String = ""
    /// 생년월일
    var birthday: String = ""
    /// 저장 중 여부
    var isSaving: Bool = false
    
    /// 저장 버튼 활성화 여부
    var isSaveEnabled: Bool {
        // 필수 필드 입력 확인
        guard !name.isEmpty,
              !phone.isEmpty,
              !height.isEmpty,
              !weight.isEmpty,
              !gender.isEmpty,
              !birthday.isEmpty else {
            return false
        }
        
        // 변경사항 확인
        guard let initial = initialProfile else {
            return false
        }
        
        return initial.name != name ||
               initial.phone != phone ||
               String(format: "%.0f", initial.height) != height ||
               String(format: "%.0f", initial.weight) != weight ||
               initial.gender != gender ||
               initial.birthday != birthday
    }
}

/// 계정 정보 수정 이벤트
enum AccountEditEvent {
    case showToast(String)
    case saveSuccess
    case navigateBack
}
