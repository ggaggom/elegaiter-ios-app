//
//  SignUpViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// SignUp 화면의 ViewModel
/// 
/// Android의 `SignUpViewModel`을 Swift로 변환
/// - SignUp과 SignUpInfo 두 화면에서 공유되는 ViewModel
/// - 기본 정보 입력 상태 관리 (SignUp 화면)
/// - 추가 정보 입력 상태 관리 (SignUpInfo 화면)
/// - ID 중복 확인 기능
/// - 회원가입 처리
@MainActor
class SignUpViewModel: ObservableObject {
    // MARK: - Published Properties (기본 정보 - SignUp 화면)
    
    /// 사용자 ID
    @Published var id: String = ""
    
    /// 비밀번호
    @Published var pw: String = ""
    
    /// 비밀번호 확인
    @Published var pwConfirm: String = ""
    
    /// 비밀번호 힌트
    @Published var pwHint: PasswordHint? = nil
    
    /// 비밀번호 힌트 답변
    @Published var pwHintAnswer: String = ""
    
    /// ID 중복 확인 완료 여부
    @Published var isIdChecked: Bool = false
    
    /// 마지막으로 확인한 ID
    @Published var lastCheckedId: String = ""
    
    /// ID 중복 확인 진행 중 여부
    @Published var isCheckingId: Bool = false
    
    /// 네트워크 온라인 상태
    @Published var isOnline: Bool = false
    
    /// 아이디 유효성 검사 통과 여부
    @Published var isIdValid: Bool = true
    
    /// 비밀번호 유효성 검사 통과 여부
    @Published var isPasswordValid: Bool = true
    
    // MARK: - Published Properties (추가 정보 - SignUpInfo 화면)
    
    /// 이름
    @Published var name: String = ""
    
    /// 성별 (M: 남성, F: 여성)
    @Published var gender: String = "M"
    
    /// 생년월일 (yyyy-MM-dd 형식)
    @Published var birthday: String = ""
    
    /// 전화번호
    @Published var phone: String = ""
    
    /// 키 (cm)
    @Published var height: String = ""
    
    /// 몸무게 (kg)
    @Published var weight: String = ""
    
    /// 회원가입 성공 다이얼로그 표시 여부
    @Published var showSuccessDialog: Bool = false
    
    /// 회원가입 진행 중 여부
    @Published var isRegistering: Bool = false
    
    // MARK: - Computed Properties
    
    /// 비밀번호 확인 일치 여부
    var isPasswordConfirm: Bool {
        pw == pwConfirm && !pwConfirm.isEmpty
    }
    
    /// 다음 버튼 활성화 여부 (SignUp 화면)
    /// 
    /// 모든 필드가 입력되고, ID 중복 확인이 완료되었으며,
    /// 현재 입력된 ID와 확인한 ID가 일치하고, 유효성 검사를 통과해야 함
    var isNextEnabled: Bool {
        !id.trimmingCharacters(in: .whitespaces).isEmpty &&
        !pw.isEmpty &&
        !pwConfirm.isEmpty &&
        pwHint != nil &&
        !pwHintAnswer.trimmingCharacters(in: .whitespaces).isEmpty &&
        isIdValid &&
        isPasswordValid &&
        isIdChecked &&
        lastCheckedId == id &&
        isPasswordConfirm
    }
    
    /// 회원가입 버튼 활성화 여부 (SignUpInfo 화면)
    var isRegisterEnabled: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !gender.isEmpty &&
        !birthday.isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !height.isEmpty &&
        !weight.isEmpty
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<SignUpUiEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<SignUpEvent, Never>()
    
    // MARK: - Initialization
    
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
    private func observeNetworkState() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .assign(to: &$isOnline)
    }
    
    /// 아이디 유효성 검사
    /// 
    /// 정규식: ^[a-zA-Z0-9]{4,12}$
    /// - 영문 또는 숫자 4-12자
    /// - Parameter id: 검사할 아이디
    private func validateId(_ id: String) {
        let trimmedId = id.trimmingCharacters(in: .whitespaces)
        // 빈 값일 때는 유효성 검사 통과로 처리 (오류 메시지 숨김)
        if trimmedId.isEmpty {
            isIdValid = true
            return
        }
        
        let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9]{4,12}$")
        let range = NSRange(location: 0, length: trimmedId.utf16.count)
        isIdValid = regex.firstMatch(in: trimmedId, options: [], range: range) != nil
    }
    
    /// 비밀번호 유효성 검사
    /// 
    /// 정규식: ^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9!@#$%^&*]{8,20}$
    /// - 영문, 숫자 포함 8-20자
    /// - Parameter password: 검사할 비밀번호
    private func validatePassword(_ password: String) {
        // 빈 값일 때는 유효성 검사 통과로 처리 (오류 메시지 숨김)
        if password.isEmpty {
            isPasswordValid = true
            return
        }
        
        let regex = try! NSRegularExpression(pattern: "^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9!@#$%^&*]{8,20}$")
        let range = NSRange(location: 0, length: password.utf16.count)
        isPasswordValid = regex.firstMatch(in: password, options: [], range: range) != nil
    }
    
    // MARK: - Public Methods (기본 정보 - SignUp 화면)
    
    /// ID 변경 처리
    /// 
    /// Android의 `IdChanged` 이벤트 처리
    /// ID가 변경되면 중복 확인 상태를 리셋하고 유효성 검사를 수행합니다.
    /// - Parameter id: 새로운 ID
    func onIdChange(_ id: String) {
        self.id = id
        // ID가 변경되면 중복 확인 상태 리셋
        if lastCheckedId != id {
            isIdChecked = false
            lastCheckedId = ""
        }
        // 아이디 유효성 검사
        validateId(id)
    }
    
    /// ID 중복 확인 버튼 클릭 처리
    /// 
    /// Android의 `CheckIdDuplication` 이벤트 처리
    func onCheckIdDuplication() {
        let trimmedId = id.trimmingCharacters(in: .whitespaces)
        
        if trimmedId.isEmpty {
            return
        }
        
        guard isOnline else {
            eventSubject.send(.showToast(message: "error_network_connection".localized()))
            return
        }
        
        isCheckingId = true
        
        Task {
            defer {
                isCheckingId = false
            }
            
            let result = await sdk.authManager.checkIdAvailability(id: trimmedId)
            
            switch result {
            case .success(let isAvailable):
                isIdChecked = isAvailable
                lastCheckedId = trimmedId
                
            case .failure:
                isIdChecked = false
                lastCheckedId = ""
            }
        }
    }
    
    /// 비밀번호 변경 처리
    /// 
    /// Android의 `PwChanged` 이벤트 처리
    /// - Parameter pw: 새로운 비밀번호
    func onPasswordChange(_ pw: String) {
        self.pw = pw
        // 비밀번호 유효성 검사
        validatePassword(pw)
    }
    
    /// 비밀번호 확인 변경 처리
    /// 
    /// Android의 `PwConfirmChanged` 이벤트 처리
    /// - Parameter pwConfirm: 새로운 비밀번호 확인
    func onPasswordConfirmChange(_ pwConfirm: String) {
        self.pwConfirm = pwConfirm
    }
    
    /// 비밀번호 힌트 선택 처리
    /// 
    /// Android의 `PwHintSelected` 이벤트 처리
    /// - Parameter hint: 선택된 힌트 (PasswordHint enum)
    func onPasswordHintSelected(_ hint: PasswordHint) {
        self.pwHint = hint
    }
    
    /// 비밀번호 힌트 답변 변경 처리
    /// 
    /// Android의 `PwHintAnswerChanged` 이벤트 처리
    /// - Parameter answer: 새로운 답변
    func onPasswordHintAnswerChange(_ answer: String) {
        self.pwHintAnswer = answer
    }
    
    /// 다음 버튼 클릭 처리
    /// 
    /// Android의 `OnNextClicked` 이벤트 처리
    /// 비밀번호 확인 검증 후 SignUpInfo 화면으로 이동합니다.
    func onNextClick() {
        // 비밀번호 확인 검증
        guard isPasswordConfirm else {
            return
        }
        
        // 모든 필드 입력 확인
        guard isNextEnabled else {
            eventSubject.send(.showToast(message: "signup_input_required".localized()))
            return
        }
        
        // SignUpInfo 화면으로 이동
        eventSubject.send(.navigateToSignUpInfo)
    }
    
    // MARK: - Public Methods (추가 정보 - SignUpInfo 화면)
    
    /// 이름 변경 처리
    func updateName(_ name: String) {
        self.name = name
    }
    
    /// 성별 변경 처리
    func updateGender(_ gender: String) {
        self.gender = gender
    }
    
    /// 생년월일 변경 처리
    func updateBirthday(_ birthday: String) {
        self.birthday = birthday
    }
    
    /// 전화번호 변경 처리
    func updatePhone(_ phone: String) {
        self.phone = phone
    }
    
    /// 키 변경 처리
    func updateHeight(_ height: String) {
        self.height = height
    }
    
    /// 몸무게 변경 처리
    func updateWeight(_ weight: String) {
        self.weight = weight
    }
    
    /// 회원가입 버튼 클릭 처리
    /// 
    /// Android의 `registerUser()` 로직을 Swift로 변환
    func registerUser() {
        guard isOnline else {
            eventSubject.send(.showToast(message: "error_network_connection".localized()))
            return
        }
        
        guard isRegisterEnabled else {
            eventSubject.send(.showToast(message: "signup_input_required".localized()))
            return
        }
        
        isRegistering = true
        
        Task {
            defer {
                isRegistering = false
            }
            
            guard let selectedHint = pwHint else {
                eventSubject.send(.showToast(message: "signup_input_required".localized()))
                return
            }
            
            let finalUserInfo = NewUserInfo(
                id: id.trimmingCharacters(in: .whitespaces),
                pass: pw,
                pwhint: selectedHint,
                pwhintAns: pwHintAnswer,  // 안드로이드와 동일: 공백 제거 없이 그대로 전달
                name: name.trimmingCharacters(in: .whitespaces),
                gender: gender,
                birthday: birthday,
                phone: phone.trimmingCharacters(in: .whitespaces),
                height: Float(height) ?? 0.0,
                weight: Float(weight) ?? 0.0
            )
            
            let result = await sdk.authManager.register(info: finalUserInfo)
            
            switch result {
            case .success:
                showSuccessDialog = true
                
            case .failure:
                eventSubject.send(.showToast(message: "sign_up_failed_message".localized()))
            }
        }
    }
    
    /// 회원가입 성공 다이얼로그 확인 버튼 클릭 처리
    /// 
    /// Android의 `onRegistrationSuccessDialogConfirmed()` 로직을 Swift로 변환
    func onRegistrationSuccessDialogConfirmed() {
        showSuccessDialog = false
        eventSubject.send(.navigateToLogin)
    }
    
    // MARK: - Navigation
    
    func navigateToSignUpInfo() {
        coordinator?.navigateInMain(to: .signUpInfo)
    }
    
    func navigateToLogin() {
        // 회원가입 플로우의 모든 화면을 pop하고 로그인 화면으로 이동
        // 안드로이드의 popUpTo<LoginRoute> { inclusive = false }와 동일한 동작
        guard let coordinator = coordinator else { return }
        
        // mainPath를 로그인 화면까지만 유지
        var newPath = NavigationPath()
        newPath.append(AppCoordinator.Route.login)
        coordinator.mainPath = newPath
    }
}
