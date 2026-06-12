//
//  FindPwViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// FindPw 화면의 ViewModel
/// 
/// Android의 `FindPwViewModel`을 Swift로 변환
/// - FindPw와 ResetPw 두 화면에서 공유되는 단일 ViewModel
/// - 비밀번호 힌트 인증 및 재설정 로직 처리
/// - 네트워크 상태 모니터링
/// - 이벤트 발생 및 처리
@MainActor
class FindPwViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "FindPwViewModel")

    // MARK: - Published Properties
    
    // 비밀번호 찾기(인증) 관련 상태
    /// 사용자 입력 아이디
    @Published var id: String = ""
    
    /// 선택된 비밀번호 힌트
    @Published var selectedHint: PasswordHint? = nil
    
    /// 힌트에 대한 답변
    @Published var answer: String = ""
    
    /// 힌트 인증 에러 여부
    @Published var hintError: Bool = false
    
    /// 비밀번호 찾기 1단계 성공 시 서버가 발급한 ResetToken (5분 유효)
    private var resetToken: String = ""
    
    // 비밀번호 재설정 관련 상태
    /// 새 비밀번호
    @Published var newPassword: String = ""
    
    /// 새 비밀번호 확인
    @Published var confirmPassword: String = ""
    
    /// 현재 비밀번호 필요 여부 (마이페이지 모드)
    @Published var requiresCurrentPassword: Bool = false
    
    /// 현재 비밀번호 (마이페이지 모드)
    @Published var currentPassword: String = ""
    
    /// 요청 진행 중 여부
    @Published var isLoading: Bool = false
    
    /// 네트워크 온라인 상태
    @Published var isOnline: Bool = false
    
    /// 새 비밀번호 유효성 검사 통과 여부
    @Published var isNewPasswordValid: Bool = true
    
    /// 다음 버튼 활성화 여부 (FindPw 화면)
    /// 
    /// 아이디, 힌트, 답변이 모두 입력되어 있고, 로딩 중이 아닐 때 활성화
    var isNextEnabled: Bool {
        !id.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedHint != nil &&
        !answer.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading
    }
    
    /// 비밀번호 재설정 버튼 활성화 여부 (ResetPw 화면)
    /// 
    /// 비밀번호가 모두 입력되고 일치하며, 유효성 검사를 통과하고, 로딩 중이 아닐 때 활성화
    /// 마이페이지 모드인 경우 현재 비밀번호도 입력되어야 함
    var isResetEnabled: Bool {
        let baseCondition = !newPassword.trimmingCharacters(in: .whitespaces).isEmpty &&
                           !confirmPassword.trimmingCharacters(in: .whitespaces).isEmpty &&
                           isNewPasswordValid &&
                           isPasswordConfirm &&
                           !isLoading
        
        if requiresCurrentPassword {
            return baseCondition && !currentPassword.trimmingCharacters(in: .whitespaces).isEmpty
        } else {
            return baseCondition
        }
    }
    
    /// 새 비밀번호와 확인 비밀번호 일치 여부
    var isPasswordConfirm: Bool {
        newPassword == confirmPassword
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<FindPwEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<FindPwEvent, Never>()
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameters:
    ///   - sdk: ElegaiterSDK 인스턴스 (기본값: 전역 SDK)
    ///   - networkMonitor: 네트워크 모니터 인스턴스 (기본값: NetworkMonitorImpl)
    ///   - coordinator: AppCoordinator 인스턴스
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        networkMonitor: NetworkMonitor = NetworkMonitorImpl(),
        coordinator: AppCoordinator? = nil
    ) {
        self.sdk = sdk
        self.networkMonitor = networkMonitor
        self.coordinator = coordinator
        
        observeNetworkState()
    }
    
    // MARK: - Private Methods
    
    /// 네트워크 상태 관찰
    /// 
    /// Android의 `networkMonitor.isOnline.stateIn()` 로직을 Combine으로 변환
    private func observeNetworkState() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
    }
    
    /// Toast 메시지 발생
    private func emitToast(_ message: String) {
        eventSubject.send(.showToast(message: message))
    }
    
    /// 비밀번호 유효성 검사
    /// 
    /// 정규식: ^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9!@#$%^&*]{8,20}$
    /// - 영문, 숫자 포함 8-20자
    /// - Parameter password: 검사할 비밀번호
    private func validatePassword(_ password: String) {
        // 빈 값일 때는 유효성 검사 통과로 처리 (오류 메시지 숨김)
        if password.isEmpty {
            isNewPasswordValid = true
            return
        }
        
        let regex = try! NSRegularExpression(pattern: "^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9!@#$%^&*]{8,20}$")
        let range = NSRange(location: 0, length: password.utf16.count)
        isNewPasswordValid = regex.firstMatch(in: password, options: [], range: range) != nil
    }
    
    // MARK: - Public Methods (비밀번호 찾기 관련)
    
    /// 아이디 변경 처리
    /// 
    /// - Parameter id: 새로운 아이디
    func onIdChange(_ id: String) {
        self.id = id
    }
    
    /// 힌트 변경 처리
    /// 
    /// - Parameter hint: 선택된 힌트 (PasswordHint enum)
    func onHintChange(_ hint: PasswordHint) {
        self.selectedHint = hint
    }
    
    /// 답변 변경 처리
    /// 
    /// 답변 입력 시 에러 상태를 리셋
    /// - Parameter answer: 새로운 답변
    func onAnswerChange(_ answer: String) {
        self.answer = answer
        // 답변 입력 시 에러 상태 리셋
        hintError = false
    }
    
    /// 다음 버튼 클릭 처리 (힌트 인증)
    /// 
    /// Android의 `onNextClick()` 로직을 Swift로 변환
    /// 1. 입력 검증
    /// 2. 힌트 인증 요청
    /// 3. 결과 처리 및 이벤트 발생
    func onNextClick() {
        // 1. 입력 검증
        let trimmedId = id.trimmingCharacters(in: .whitespaces)
        
        // 안드로이드와 동일: answer는 공백 제거 없이 그대로 전달
        // (안드로이드: pwhintAns = idState.pwHintAnswer - 공백 제거 없음)
        guard let hint = selectedHint else {
            emitToast("find_pw_input_required".localized())
            return
        }
        
        if trimmedId.isEmpty || answer.isEmpty {
            emitToast("find_pw_input_required".localized())
            return
        }
        
        // 2. 힌트 인증 요청
        isLoading = true
        
        Task {
            defer {
                isLoading = false
            }
            
            logger.debug("[FindPwViewModel] verifyPasswordHint 호출 - id: \(trimmedId), hint: \(hint.rawValue), answer: \(self.answer)")
            
            let result = await sdk.authManager.verifyPasswordHint(
                id: trimmedId,
                hint: hint,
                answer: answer  // 안드로이드와 동일: 공백 제거 없이 그대로 전달
            )
            
            // 3. 결과 처리
            switch result {
            case .success(let token):
                resetToken = token
                emitToast("find_pw_auth_completed".localized())
                eventSubject.send(.navigateToResetPw)

            case .failure(let error as AuthError) where error == .invalidHint:
                hintError = true

            case .failure:
                emitToast("error_occurred".localized())
            }
        }
    }
    
    // MARK: - Public Methods (비밀번호 재설정 관련)
    
    /// 새 비밀번호 변경 처리
    /// 
    /// - Parameter password: 새로운 비밀번호
    func onNewPasswordChange(_ password: String) {
        self.newPassword = password
        // 비밀번호 유효성 검사
        validatePassword(password)
    }
    
    /// 확인 비밀번호 변경 처리
    /// 
    /// - Parameter password: 확인 비밀번호
    func onConfirmPasswordChange(_ password: String) {
        self.confirmPassword = password
    }
    
    /// 현재 비밀번호 필요 여부 초기화
    /// 
    /// ResetPw 화면 진입 시 호출
    /// - Parameter required: 현재 비밀번호 필요 여부
    func initializeRequireCurrentPw(_ required: Bool) {
        self.requiresCurrentPassword = required
    }
    
    /// 현재 비밀번호 변경 처리
    /// 
    /// - Parameter password: 현재 비밀번호
    func onCurrentPasswordChange(_ password: String) {
        self.currentPassword = password
    }
    
    /// 비밀번호 재설정 버튼 클릭 처리
    /// 
    /// Android의 `onResetClick()` 로직을 Swift로 변환
    /// 1. 네트워크 확인
    /// 2. 모드에 따라 분기 (마이페이지 모드 vs 비밀번호 찾기 모드)
    /// 3. SDK 호출 및 결과 처리
    func onResetClick() {
        // 1. 네트워크 확인
        if !isOnline {
            emitToast("error_network_connection".localized())
            return
        }
        
        // 2. 모드에 따라 분기
        if requiresCurrentPassword {
            // 마이페이지 비밀번호 변경 모드
            handleChangePassword()
        } else {
            // 비밀번호 찾기 모드
            handleResetLostPassword()
        }
    }
    
    /// 마이페이지 비밀번호 변경 처리
    private func handleChangePassword() {
        // 안드로이드와 동일: 공백 제거 없이 그대로 전달
        // Android: currentPassword = _uiState.value.currentPassword, newPassword = _uiState.value.newPassword
        isLoading = true
        
        Task {
            defer {
                // 안드로이드와 동일: isLoading은 항상 마지막에 false로 설정
                isLoading = false
            }
            
            let result = await sdk.authManager.changePassword(
                currentPassword: currentPassword,  // 공백 제거 없이 그대로 전달
                newPassword: newPassword  // 공백 제거 없이 그대로 전달
            )
            
            switch result {
            case .success:
                emitToast("find_pw_changed".localized())
                eventSubject.send(.navigateToSetting)
                
            case .failure:
                emitToast("find_pw_error".localized())
            }
        }
    }
    
    /// 비밀번호 찾기 모드 재설정 처리
    private func handleResetLostPassword() {
        isLoading = true
        
        Task {
            defer {
                isLoading = false
            }
            
            let result = await sdk.authManager.resetLostPassword(
                newPassword: newPassword,
                token: resetToken
            )
            
            switch result {
            case .success:
                emitToast("find_pw_changed_login".localized())
                eventSubject.send(.navigateToLogin)

            case .failure(let error as AuthError) where error == .tokenExpired:
                emitToast("find_pw_token_expired".localized())
                answer = ""
                resetToken = ""
                newPassword = ""
                confirmPassword = ""
                isNewPasswordValid = true
                eventSubject.send(.navigateToVerifyHint)

            case .failure:
                emitToast("find_pw_change_failed".localized())
            }
        }
    }
    
    /// FindPw 화면 진입 시 답변 필드 초기화
    func clearVerificationAnswer() {
        answer = ""
        hintError = false
    }
    
    // MARK: - Navigation
    
    func navigateToResetPw(requiresCurrentPassword: Bool) {
        coordinator?.navigateInMain(to: .resetPw(requiresCurrentPassword: requiresCurrentPassword))
    }
    
    func navigateToLogin() {
        coordinator?.navigateInMain(to: .login)
    }
    
    func navigateToSetting() {
        coordinator?.navigateInMain(to: .setting)
    }
    
    /// 로딩 상태 설정 (외부에서 호출용)
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}
