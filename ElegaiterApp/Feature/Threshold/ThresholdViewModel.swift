//
//  ThresholdViewModel.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import Combine
import ElegaiterSDK

/// Threshold 설정 화면의 ViewModel
/// 
/// Android의 `ThresholdViewModel`을 Swift로 변환
/// - 임계값 자동/수동 설정
/// - 현재 설정값 확인
/// - SDK의 BleManager와 통합
@MainActor
class ThresholdViewModel: ObservableObject {
    weak var coordinator: AppCoordinator?
    
    private let sdk: ElegaiterSdk
    private let deviceRepository: DeviceRepository
    private var cancellables = Set<AnyCancellable>()
    
    /// 이벤트 Subject
    /// 
    /// Android의 `MutableSharedFlow<ThresholdEvent>`를 `PassthroughSubject`로 변환
    let eventSubject = PassthroughSubject<ThresholdEvent, Never>()
    
    // MARK: - Published Properties
    
    /// UI 상태
    @Published var uiState = ThresholdUiState()
    
    // MARK: - Initialization
    
    init(
        sdk: ElegaiterSdk = SDKManager.shared.sdk,
        deviceRepository: DeviceRepository? = nil,
        coordinator: AppCoordinator? = nil
    ) {
        self.sdk = sdk
        self.deviceRepository = deviceRepository ?? DeviceRepositoryImpl()
        self.coordinator = coordinator
        observeThresholdResponse()
        loadShouldShowThresholdPrompt()
    }
    
    // MARK: - Private Methods
    
    /// Threshold 응답 구독
    /// 
    /// Android의 `init` 블록에서 `thresholdResponse` Flow를 구독하는 로직을 Swift로 변환
    /// - SDK의 `bleManager.threshold` Publisher를 구독
    /// - 디바이스로부터 `T1_{value}` 형식의 응답 수신 시 UI 상태 업데이트
    private func observeThresholdResponse() {
        sdk.bleManager.threshold
            .receive(on: DispatchQueue.main)
            .sink { [weak self] thresholdValue in
                guard let self = self else { return }
                if let value = thresholdValue {
                    self.uiState.currentThreshold = String(format: "%04d", value)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 드롭다운에서 Threshold 값을 선택했을 때 호출
    /// 
    /// Android의 `onThresholdSelected()` 함수를 Swift로 변환
    /// - Parameter newValue: 선택된 값 (4자리 문자열)
    func onThresholdSelected(_ newValue: String) {
        uiState.selectedThreshold = newValue
    }
    
    /// Threshold 자동 설정
    /// 
    /// Android의 `setAutoThreshold()` 함수를 Swift로 변환
    /// - `T4_0` 명령 전송 (자동 설정)
    /// - 신규 디바이스는 설정 완료 후 데이터를 반환하므로 T2(설정값 조회) 별도 전송 없음
    func setAutoThreshold() {
        Task {
            uiState.isLoading = true
            
            let result = await sdk.bleManager.setAutoThreshold()
            switch result {
            case .success:
                uiState.isEnable = true
                eventSubject.send(.showToast(message: "toast_save_success".localized()))
            case .failure:
                // 에러 처리 (현재는 빈 블록, 향후 개선 필요)
                break
            }
            
            uiState.isLoading = false
        }
    }
    
    /// 현재 Threshold 확인
    /// 
    /// Android의 `checkCurrentThreshold()` 함수를 Swift로 변환
    /// - `T2` 명령 전송
    /// - 디바이스로부터 `T1_{value}` 형식의 응답 수신 (observeThresholdResponse에서 처리)
    func checkCurrentThreshold() {
        Task {
            uiState.isLoading = true
            _ = await sdk.bleManager.checkThreshold()
            uiState.isLoading = false
        }
    }
    
    /// 선택된 Threshold로 수동 설정
    /// 
    /// Android의 `setManualThreshold()` 함수를 Swift로 변환
    /// - 드롭다운에서 선택한 값을 정수로 변환
    /// - `T4_{value}` 명령 전송
    /// - 신규 디바이스는 설정 완료 후 데이터를 반환하므로 T2(설정값 조회) 별도 전송 없음
    func setManualThreshold() {
        guard let value = Int(uiState.selectedThreshold) else {
            return
        }
        
        Task {
            uiState.isLoading = true
            
            let result = await sdk.bleManager.setThreshold(level: value)
            switch result {
            case .success:
                uiState.isEnable = true
                eventSubject.send(.showToast(message: "toast_save_success".localized()))
            case .failure:
                // 에러 처리 (현재는 빈 블록, 향후 개선 필요)
                break
            }
            
            uiState.isLoading = false
        }
    }
    
    // MARK: - Navigation
    
    /// Threshold 설정 완료
    /// 
    /// 임계값 설정 완료 시:
    /// - JawsSearch 이후 진입한 경우: 로그인 상태로 전환하고 운동 홈으로 이동
    /// - Setting에서 진입한 경우: Setting으로 돌아가기
    func completeThresholdSetup() {
        guard let coordinator = coordinator else { return }
        
        // Setting에서 진입한 경우: JawsSearch·Threshold 모두 제거하여 마이페이지로
        if !coordinator.settingPath.isEmpty {
            coordinator.settingPath = NavigationPath()
        } else {
            // JawsSearch 이후 진입한 경우: 로그인 상태로 전환하고 운동 홈(루트)으로 이동
            // navigateInExercise 사용 시 exercisePath에 push되어 백 버튼이 표시되므로,
            // exercisePath를 비워 루트(ExerciseReadyView)로 표시
            coordinator.isLoggedIn = true
            coordinator.switchTab(to: .exercise)
            coordinator.exercisePath = NavigationPath()
        }
    }
    
    /// 임계값 재설정 팝업 표시 여부 상태를 토글하고 변경된 값을 저장소에 비동기적으로 저장합니다.
    /// 
    /// Android의 `toggleShouldShowThresholdPrompt()` 함수를 Swift로 변환
    func toggleShouldShowThresholdPrompt() {
        Task {
            let newValue = !uiState.shouldShowThresholdPrompt
            uiState.shouldShowThresholdPrompt = newValue
            
            await deviceRepository.saveShouldShowThresholdPrompt(newValue)
            // 팝업 설정 변경 성공 토스트 이벤트 발생
            eventSubject.send(.showToast(message: "threshold_popup_setting_changed".localized()))
        }
    }
    
    /// 임계값 재설정 팝업 표시 여부를 로드합니다.
    /// 
    /// Android의 `init` 블록에서 `loadShouldShowThresholdPrompt()` 호출 로직을 Swift로 변환
    private func loadShouldShowThresholdPrompt() {
        Task {
            let shouldShow = await deviceRepository.loadShouldShowThresholdPrompt()
            uiState.shouldShowThresholdPrompt = shouldShow
        }
    }
}

/// Threshold UI 상태
/// 
/// Android의 `ThresholdUiState` data class를 Swift struct로 변환
struct ThresholdUiState {
    /// 현재 디바이스에 설정된 임계값 (기본값: "-")
    var currentThreshold: String = "-"
    /// 사용자가 드롭다운에서 선택한 임계값
    var selectedThreshold: String = ""
    /// 로딩 상태 (명령 전송 중)
    var isLoading: Bool = false
    /// 다음 단계로 진행 가능 여부 (임계값 설정 완료 시 `true`)
    var isEnable: Bool = false
    /// 임계값 재설정 다이얼로그를 사용자에게 보여줘야 하는지 여부 (기본값: true)
    var shouldShowThresholdPrompt: Bool = true
}
