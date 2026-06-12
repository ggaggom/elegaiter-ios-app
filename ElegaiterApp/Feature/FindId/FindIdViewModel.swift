//
//  FindIdViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// FindId 화면의 ViewModel
/// 
/// Android의 `FindIdViewModel`을 Swift로 변환
/// - 사용자 입력 관리 (이름, 전화번호)
/// - 아이디 찾기 로직 처리
/// - 네트워크 상태 모니터링
/// - 이벤트 발생 및 처리
@MainActor
class FindIdViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 사용자 입력 이름
    @Published var name: String = ""
    
    /// 사용자 입력 전화번호
    @Published var phone: String = ""
    
    /// 아이디 찾기 요청 진행 중 여부
    @Published var isLoading: Bool = false
    
    /// 네트워크 온라인 상태
    @Published var isOnline: Bool = false
    
    /// 찾은 아이디 (nil이 아니면 다이얼로그 표시)
    @Published var foundId: String? = nil
    
    /// 확인 버튼 활성화 여부
    /// 
    /// 이름과 전화번호가 모두 입력되어 있고, 로딩 중이 아닐 때 활성화
    var isFindIdEnabled: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty &&
        !isLoading
    }
    
    // MARK: - Properties
    
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    /// 이전 전화번호의 숫자 개수 (삭제 감지용)
    private var previousPhoneNumberCount: Int = 0
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<FindIdEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<FindIdEvent, Never>()
    
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
    
    /// 이름 변경 처리
    /// 
    /// - Parameter name: 새로운 이름
    func onNameChange(_ name: String) {
        self.name = name
    }
    
    /// 전화번호 변경 처리
    /// 
    /// [현재 비활성화] 입력 중 자동으로 포맷팅하여 표시
    /// [현재 비활성화] 삭제 동작도 정상적으로 처리되도록 이전 값과 비교
    /// - Parameter phone: 새로운 전화번호 (숫자만 입력 또는 포맷팅된 형태)
    /// 
    /// 현재는 숫자만 추출하여 그대로 사용 (포맷팅 비활성화)
    func onPhoneChange(_ phone: String) {
        // 숫자만 추출하여 그대로 사용 (포맷팅 비활성화)
        let inputNumbers = PhoneNumberFormatter.extractNumbers(phone)
        // 최대 11자리까지만 입력 허용
        let limitedNumbers = String(inputNumbers.prefix(11))
        
        // 포맷팅 없이 숫자만 그대로 사용
        self.phone = limitedNumbers
        previousPhoneNumberCount = limitedNumbers.count
        
        // ========== [주석 처리됨] 자동 하이픈 포맷팅 기능 ==========
        // 나중에 다시 활성화할 수 있도록 코드는 유지하되 주석 처리
        /*
        // 입력된 값의 숫자만 추출
        let inputNumbers = PhoneNumberFormatter.extractNumbers(phone)
        
        // 현재 저장된 값의 숫자만 추출
        let currentStoredNumbers = PhoneNumberFormatter.extractNumbers(self.phone)
        
        // 숫자가 실제로 변경되지 않았고, 포맷팅만 다른 경우 (무한 루프 방지)
        // 단, 빈 문자열인 경우는 허용 (초기화)
        if !inputNumbers.isEmpty && inputNumbers == currentStoredNumbers {
            // 숫자가 같고 포맷팅만 다른 경우
            // 이미 포맷팅된 값이면 그대로 유지, 아니면 포맷팅 적용
            let formatted = PhoneNumberFormatter.format(inputNumbers)
            if formatted != self.phone {
                self.phone = formatted
            }
            return
        }
        
        // 최대 11자리까지만 입력 허용
        let limitedNumbers = String(inputNumbers.prefix(11))
        
        // 포맷팅 적용
        let formatted = PhoneNumberFormatter.format(limitedNumbers)
        
        // 포맷팅된 결과를 항상 업데이트 (숫자가 변경되었으므로)
        self.phone = formatted
        previousPhoneNumberCount = PhoneNumberFormatter.extractNumbers(formatted).count
        */
    }
    
    /// 아이디 찾기 버튼 클릭 처리
    /// 
    /// Android의 `onFindIdClick()` 로직을 Swift로 변환
    /// 1. 네트워크 확인
    /// 2. 입력 검증
    /// 3. 아이디 찾기 요청
    /// 4. 결과 처리 및 이벤트 발생
    func onFindIdClick() {
        // 1. 네트워크 확인
        if !isOnline {
            eventSubject.send(.showToast(message: "error_network_connection".localized()))
            return
        }
        
        // 2. 입력 검증
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        
        if trimmedName.isEmpty || trimmedPhone.isEmpty {
            eventSubject.send(.showToast(message: "find_id_input_required".localized()))
            return
        }
        
        // 전화번호 유효성 검증
        if !PhoneNumberFormatter.isValid(trimmedPhone) {
            eventSubject.send(.showToast(message: "find_id_invalid_phone".localized()))
            return
        }
        
        // 3. API 호출 전 전화번호 정규화 (하이픈 포함 형태로 변환)
        let normalizedPhone = PhoneNumberFormatter.normalize(trimmedPhone)
        
        // 4. 아이디 찾기 요청
        isLoading = true
        
        Task {
            defer {
                isLoading = false
            }
            
            let result = await sdk.authManager.findId(name: trimmedName, phone: normalizedPhone)

            // 4. 결과 처리 (서버는 미일치 시 Data/UserId를 null로 반환, Android FindIdViewModel과 동일)
            switch result {
            case .success(let foundId):
                if let id = foundId, !id.isEmpty {
                    // 찾은 아이디를 상태에 저장하여 다이얼로그 표시
                    self.foundId = id
                } else {
                    // 일치하는 아이디 없음
                    eventSubject.send(.showToast(message: "find_id_not_found".localized()))
                }
                
            case .failure(let error):
                // 에러 메시지 표시
                eventSubject.send(.showToast(message: "error_network_connection".localized()))
            }
        }
    }
    
    /// 다이얼로그 확인 버튼 클릭 처리 (로그인으로 이동)
    func onDialogConfirm() {
        foundId = nil
        eventSubject.send(.navigateToLogin)
    }
    
    /// 다이얼로그에서 비밀번호 찾기로 이동
    func onDialogNavigateToFindPassword() {
        foundId = nil
        eventSubject.send(.navigateToFindPassword)
    }
    
    // MARK: - Navigation
    
    func navigateToLogin() {
        coordinator?.navigateInMain(to: .login)
    }
    
    func navigateToFindPassword() {
        // 안드로이드와 동일: FindIdRoute를 백스택에서 제거하고 FindPw로 이동
        // 비밀번호 찾기 화면에서 뒤로가기 시 로그인 화면으로 돌아감
        coordinator?.popToRouteAndNavigate(popToRoute: .findId, navigateToRoute: .findPw, inclusive: true)
    }
}
