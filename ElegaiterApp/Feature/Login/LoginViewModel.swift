//
//  LoginViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK
import os.log

/// Login 화면의 ViewModel
/// 
/// Android의 `LogInViewModel`을 Swift로 변환
/// - 사용자 입력 관리
/// - 로그인 로직 처리
/// - 네트워크 상태 모니터링
/// - 이벤트 발생 및 처리
@MainActor
class LoginViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.elegaiter.app", category: "LoginViewModel")

    // MARK: - Published Properties
    
    /// 사용자 입력 아이디
    @Published var id: String = {
        #if DEBUG
        // return "yiwoo456"
        return ""
        #else
        return ""
        #endif
    }()
    
    /// 사용자 입력 비밀번호
    @Published var password: String = {
        #if DEBUG
        // return "aaa111!!!"
        return ""
        #else
        return ""
        #endif
    }()
    
    /// 자동 로그인 체크박스 상태 (기본값: true)
    @Published var isAutoLogin: Bool = true
    
    /// 로그인 요청 진행 중 여부
    @Published var isLoading: Bool = false
    
    /// 네트워크 온라인 상태
    @Published var isOnline: Bool = false
    
    /// 로그인 버튼 활성화 여부
    /// 
    /// 아이디와 비밀번호가 모두 입력되어 있고, 로딩 중이 아닐 때 활성화
    var isLoginEnabled: Bool {
        !id.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<LoginEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<LoginEvent, Never>()
    
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
    
    // MARK: - Public Methods
    
    /// 아이디 변경 처리
    /// 
    /// - Parameter id: 새로운 아이디
    func onIdChange(_ id: String) {
        self.id = id
    }
    
    /// 비밀번호 변경 처리
    /// 
    /// - Parameter password: 새로운 비밀번호
    func onPasswordChange(_ password: String) {
        self.password = password
    }
    
    /// 자동 로그인 체크박스 변경 처리
    /// 
    /// - Parameter isChecked: 체크 상태
    func onAutoLoginChange(_ isChecked: Bool) {
        self.isAutoLogin = isChecked
    }
    
    /// 로그인 버튼 클릭 처리
    /// 
    /// Android의 `onLoginClick()` 로직을 Swift로 변환
    /// 1. 입력 검증
    /// 2. 로그인 요청
    /// 3. 결과 처리 및 이벤트 발생
    func onLoginClick() {
        // 1. 입력 검증
        let trimmedId = id.trimmingCharacters(in: .whitespaces)
        let trimmedPassword = password.trimmingCharacters(in: .whitespaces)

        /*        
        if trimmedId.isEmpty || trimmedPassword.isEmpty {
            eventSubject.send(.loginFailure(message: "login_input_required".localized()))
            return
        }
        */

        
        // 2. 로그인 요청
        isLoading = true
        
        Task {
            defer {
                isLoading = false
            }
            
            let result = await sdk.authManager.login(
                id: trimmedId,
                password: trimmedPassword,
                isAutoLogin: isAutoLogin
            )
            
            // 3. 결과 처리
            switch result {
            case .success:
                await ReviewDemoDataSeeder.seedIfNeeded(userId: trimmedId, sdk: sdk)
                eventSubject.send(.loginSuccess)
                
            case .failure(let error):
                // 네트워크 에러인지 확인
                let errorDescription = error.localizedDescription
                let errorMessage: String
                if !isOnline {
                    errorMessage = "error_network_connection".localized()
                } else {
                    // 에러 메시지에서 상세 정보 추출
                    let detailedMessage = errorDescription
                    if detailedMessage.contains("Login failed") {
                        // SDK에서 반환한 상세 메시지 사용
                        let serverMessage = detailedMessage.replacingOccurrences(of: "Login failed: ", with: "")
                        // 서버 메시지가 "fail" 같은 의미 없는 값이면 로컬라이즈된 메시지 사용
                        let meaninglessMessages = ["fail", "error", "failed", "failure"]
                        if meaninglessMessages.contains(serverMessage.lowercased()) {
                            errorMessage = "login_fail".localized()
                        } else {
                            // 서버에서 의미 있는 메시지를 반환한 경우 그대로 사용
                            errorMessage = serverMessage
                        }
                    } else if detailedMessage.contains("HTTP error:") {
                        // HTTP 상태 코드 추출
                        let components = detailedMessage.components(separatedBy: "HTTP error: ")
                        if components.count > 1 {
                            let statusCodeStr = components[1].components(separatedBy: " ").first ?? ""
                            if let statusCode = Int(statusCodeStr) {
                                if statusCode == 401 || statusCode == 403 {
                                    errorMessage = "login_fail".localized()
                                } else {
                                    errorMessage = "login_server_error_with_code".localized(format: statusCode)
                                }
                            } else {
                                errorMessage = "login_server_error_with_message".localized(format: detailedMessage)
                            }
                        } else {
                            errorMessage = "login_server_error_with_message".localized(format: detailedMessage)
                        }
                    } else if detailedMessage.contains("Network error") {
                        errorMessage = "login_network_error".localized()
                    } else if detailedMessage.contains("Decoding error") {
                        errorMessage = "login_server_response_error".localized()
                    } else {
                        errorMessage = "login_fail".localized()
                    }
                }
                
                eventSubject.send(.loginFailure(message: errorMessage))
            }
        }
    }
    
    // MARK: - Navigation
    
    func navigateToSignUp() {
        coordinator?.navigateInMain(to: .toS)
    }
    
    func navigateToFindId() {
        coordinator?.navigateInMain(to: .findId)
    }
    
    func navigateToFindPw() {
        coordinator?.navigateInMain(to: .findPw)
    }
    
    func handleLoginSuccess() {
        logger.debug("🚀 [Login] handleLoginSuccess 호출됨")
        coordinator?.navigateInMain(to: .jawsSearch)
        logger.debug("🚀 [Login] JawsSearch 화면으로 이동 완료")
    }
}
